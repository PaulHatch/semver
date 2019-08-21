#!/bin/bash

declare BRANCH_FOLDER="release"
declare RESULT_TYPE=""
declare PREVIEW_PREFIX="preview"
declare ROOT_BRANCH="HEAD"

declare MAJOR_KEYWORD="[MAJOR]"
declare MINOR_KEYWORD="[FEATURE]"

while (( "$#" )); do
  case "$1" in
    -f|--folder)
      BRANCH_FOLDER=$2
      shift 2
      ;;
    -o|--output)
      RESULT_TYPE=$2
      shift 2
      ;;
    -M|--major)
      MAJOR_KEYWORD=$2
      shift 2
      ;;
    -m|--minor)
      MINOR_KEYWORD=$2
      shift 2
      ;;
    -p|--preview)
      PREVIEW_PREFIX=$2
      shift 2
      ;;
    --product)
      PRODUCT=${2}
      BRANCH_FOLDER="release-${PRODUCT}"
      PRODUCT=$(echo ${PRODUCT} | tr '[:lower:]' '[:upper:]')
      MINOR_KEYWORD="[MINOR:${PRODUCT}]"
      MAJOR_KEYWORD="[MAJOR:${PRODUCT}]"
      shift 2
      ;;
    *) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
  esac
done

if [ -z "$RESULT_TYPE" ] ; then
    echo "Usage:"
    echo " -f --folder      Specify the branch 'folder' to use, default is 'release'"
    echo " -o --output      Sets the output type, required"
    echo "                     last    - the most recent published version"
    echo "                     next    - the next version for a new build"
    echo "                     full    - the next version including build number"
    echo "                     release - the full version in form 1.0.0+0"
    echo "                     preview - the preview version 1.0.0-preview1"
    echo "                     branch  - name of next release branch"
    echo "                     info    - displays all version"
    echo " -m --minor       Sets minor version keyword, default is [MINOR]"
    echo " -M --Major       Sets major version keyword, default is [MAJOR]"
    echo " -p --preview     Sets the preview version prefix, default is 'preview'"
    echo " --product        Sets branch and keywords using namespace"
    exit
fi

declare TAG
declare BRANCH=$(git branch --list --format='%(refname:short)' --merged ${ROOT_BRANCH} --sort='-*committerdate' ${BRANCH_FOLDER}/* | head -1)

if [ -z "$BRANCH" ] ; then
    BRANCH=${ROOT_BRANCH}
else
    TAG=$(echo $BRANCH | awk -F'/' '{print $2}')
fi

declare ROOT=$(git merge-base $BRANCH $ROOT_BRANCH)
declare FEATURE_COUNT=$(git log --pretty="format:%s" ${ROOT}..${ROOT_BRANCH} | grep -cF ${MINOR_KEYWORD})
declare BREAKING_COUNT=$(git log --pretty="format:%s" ${ROOT}..${ROOT_BRANCH} | grep -cF ${MAJOR_KEYWORD})
declare RELEASE_FIXES=$(git rev-list --count ${ROOT}..${BRANCH})

declare TYPE
declare REV
declare NEXT

# If no previous tags then this is the first release
if [ -z "$TAG" ] ; then
  TAG=0.0.0
  NEXT=0.0.0
  TYPE=NEW
  REV=$(git rev-list --count ${ROOT_BRANCH})
else

  declare P=( ${TAG//./ } )

  if [ $BREAKING_COUNT -ne 0 ] ; then
    TYPE=MAJOR
    REV=$(git log --pretty="format:%s" ${ROOT}..${ROOT_BRANCH} | sed /""${MAJOR_KEYWORD}""/q | wc -l | xargs echo)
    ((REV--))
    ((P[0]++))
    P[1]=0
    P[2]=0
  elif [ $FEATURE_COUNT -ne 0 ] ; then
    TYPE=MINOR
    REV=$(git log --pretty="format:%s" ${ROOT}..${ROOT_BRANCH} | sed /""${MAJOR_KEYWORD}""/q | wc -l | xargs echo)
    ((REV--))
    ((P[1]++))
    P[2]=0
  else
    TYPE=PATCH
    REV=$(git rev-list --count ${ROOT}..${ROOT_BRANCH})
    ((P[2]++))
  fi

  NEXT=${P[0]}.${P[1]}.${P[2]}
fi

case $RESULT_TYPE in
  "last")
    echo "${TAG}"
    ;;
  "next")
    echo "${NEXT}"
    ;;
  "full")
    echo "${NEXT}.${REV}"
    ;;
  "release")
    echo "$TAG+$RELEASE_FIXES"
    ;;
  "preview")
    echo "${NEXT}-${PREVIEW_PREFIX}${REV}"
    ;;
  "branch")
    echo "${BRANCH_FOLDER}/${NEXT}"
    ;;
  *)
    echo "Version Information"
    echo "Current:     ${TAG}"
    echo "Release:     ${TAG}+${RELEASE_FIXES}"
    echo "Next:        ${NEXT}"
    echo "Full:        ${NEXT}.${REV}"
    echo "Preview:     ${NEXT}-${PREVIEW_PREFIX}${REV}"
    echo ""
    echo "Type:        ${TYPE}"
    echo "Revision:    ${REV}"
    echo "Breaking:    ${BREAKING_COUNT} change(s)"
    echo "Features:    ${FEATURE_COUNT} change(s)"
    ;;
esac