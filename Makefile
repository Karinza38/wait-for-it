module:=wait_for_it
project:=wait-for-it
version:=$(shell python3 -c 'import sys, os; sys.path.insert(0, os.path.abspath(".")); print(__import__("${module}").__version__)')

.PHONY: list
list help:
	@make -pq | awk -F':' '/^[a-zA-Z0-9][^$$#\/\t=]*:([^=]|$$)/ {split($$1,A,/ /);for(i in A)print A[i]}' | sed '/Makefile/d' | sort

.PHONY: format
format:
	python3 -m black .

.PHONY: build
build:
	rm -rf ./dist/*
	python3 setup.py sdist bdist_wheel

.PHONY: test
test:
	@echo "not implemented"

.PHONY: clean
clean:
	rm -rf ./dist ./build ./*.egg-info ./htmlcov
	find . -name '*.pyc' -delete
	find . -name '__pycache__' -delete

.PHONY: check
check:
	twine check dist/*

.PHONY: upload-test
upload-test: test clean build check
	twine upload --repository-url https://test.pypi.org/legacy/ dist/*

.PHONY: upload-test
install-test:
	pip3 install --force-reinstall --index-url https://test.pypi.org/simple "${project}"

.PHONY: tag
tag:
ifeq (,$(shell git tag --list | grep "${version}"))
	git tag "v${version}"
endif

.PHONY: release
release: tag
ifdef version
	curl -XPOST \
	-H "Authorization: token ${GITHUB_ACCESS_TOKEN}" \
	-H "Content-Type: application/json" \
	"https://api.github.com/repos/clarketm/${project}/releases" \
	--data "{\"tag_name\": \"v${version}\",\"target_commitish\": \"master\",\"name\": \"v${version}\",\"draft\": false,\"prerelease\": false}"
	git push --tags
endif

.PHONY: upload
publish upload: test clean build check release
	twine upload dist/*

.PHONY: install
install:
	pip3 install --force-reinstall "${project}"
