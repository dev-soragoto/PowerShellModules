#!/bin/sh
# Pre-commit hook Check for sensitive information

PATTERNS="GH_TOKEN GITHUB_TOKEN API_KEY SECRET PASSWORD"

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)

FOUND=0

for FILE in $STAGED_FILES; do
	DIFF_CONTENT=$(git diff --cached "$FILE")
	for PATTERN in $PATTERNS; do
		if echo "$DIFF_CONTENT" | grep -q "$PATTERN"; then
			echo "Sensitive information detected in $FILE: $PATTERN"
			FOUND=1
		fi
	done
done

if [ $FOUND -eq 1 ]; then
	echo "Commit blocked! Please remove sensitive information before committing."
	exit 1
fi

exit 0
