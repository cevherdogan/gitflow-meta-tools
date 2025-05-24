.PHONY: help release push

help:
	@echo "Available targets:"
	@echo "  release     Run tag-release.sh with automatic versioning"
	@echo "  push        Push code and tags to origin"
	@echo "  info        Show current version"

release:
	./tag-release.sh --minor

push:
	git push origin main --tags

info:
	./tag-release.sh --info

