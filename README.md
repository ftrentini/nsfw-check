# nsfw-check
Bash script to use with https://github.com/tmplink/nsfw_detector


How to Use:

Simple Analysis:
bash nsfw_scan.sh /caminho/para/imagens

Resume:
bash nsfw_scan.sh --resume /caminho/para/imagens

Move NSFW images to scan_results/nsfw/:
bash nsfw_scan.sh --move-nsfw /caminho/para/imagens

Everything:
bash nsfw_scan.sh --resume --move-nsfw /caminho/para/imagens

visualizar.py: Generates a graphic output of found NSFW files.

pip install matplotlib pandas

python visualizar.py
