#!/bin/bash

# Configurações
API_URL="http://localhost:3333/check"
THRESHOLD=0.90
RESUME_MODE=false
MOVE_NSFW=false
RESULTS_DIR="./scan_results"
CSV_LOG="$RESULTS_DIR/scan_report.csv"

# Parse de argumentos
while [[ "$1" != "" ]]; do
    case "$1" in
        -r|--resume) RESUME_MODE=true ;;
        --move-nsfw) MOVE_NSFW=true ;;
        *) DIR_PATH="$1" ;;
    esac
    shift
done

# Verifica diretório de entrada
if [[ -z "$DIR_PATH" || ! -d "$DIR_PATH" ]]; then
    echo "Usage: $0 [--resume] [--move-nsfw] /path/to/images"
    exit 1
fi

# Cria pasta de resultados
mkdir -p "$RESULTS_DIR"

# Inicia CSV se não for modo resume
if ! $RESUME_MODE || [[ ! -f "$CSV_LOG" ]]; then
    echo "file_path,nsfw_score,label" > "$CSV_LOG"
fi

# Mapeia arquivos já processados
declare -A PROCESSED
if [[ -f "$CSV_LOG" ]]; then
    tail -n +2 "$CSV_LOG" | while IFS=, read -r FILE SCORE LABEL; do
        PROCESSED["$FILE"]=1
    done
fi

# Contadores
NSFW_COUNT=0
SAFE_COUNT=0
PROCESSED_FILES=0
TOTAL_FILES=$(find "$DIR_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | wc -l)

# Função para mover mantendo estrutura
move_preserving_structure() {
    local FILE_PATH="$1"
    local RELATIVE_PATH="${FILE_PATH#$DIR_PATH/}"
    local DEST_PATH="$RESULTS_DIR/nsfw/$RELATIVE_PATH"
    mkdir -p "$(dirname "$DEST_PATH")"
    mv "$FILE_PATH" "$DEST_PATH"
}

# Função principal
analyze_image() {
    local IMAGE_PATH="$1"

    if $RESUME_MODE && [[ ${PROCESSED["$IMAGE_PATH"]+exists} ]]; then
        return
    fi

    RESPONSE=$(curl -s -X POST -F "file=@$IMAGE_PATH" "$API_URL")
    NSFW_SCORE=$(echo "$RESPONSE" | jq -r '.result.nsfw')

    LABEL="SAFE"
    if (( $(echo "$NSFW_SCORE > $THRESHOLD" | bc -l) )); then
        LABEL="NSFW"
        ((NSFW_COUNT++))
        $MOVE_NSFW && move_preserving_structure "$IMAGE_PATH"
    else
        ((SAFE_COUNT++))
    fi

    echo "\"$IMAGE_PATH\",$NSFW_SCORE,$LABEL" >> "$CSV_LOG"

    ((PROCESSED_FILES++))
    printf "\rNSFW: %d  SAFE: %d  PROGRESS: %d/%d" "$NSFW_COUNT" "$SAFE_COUNT" "$PROCESSED_FILES" "$TOTAL_FILES"
}

# Loop principal
find "$DIR_PATH" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | while read IMAGE; do
    analyze_image "$IMAGE"
done

echo -e "\n✅ Scan completed!"
