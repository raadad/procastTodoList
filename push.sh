rsync --exclude ".git" --exclude "template" --exclude "node_modules" -rvaz -e ssh ./ raadad@env:/srv/procast/site
