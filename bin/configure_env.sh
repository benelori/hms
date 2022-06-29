#!/bin/bash

set -o allexport
set -e

grn="\e[1;32m"
yel="\e[1;33m"
end="\e[0m"

if [ "$CI" == "" ]; then
  #Mac workaround
  if [ "$(uname)" == "Darwin" ]; then
    IP=$(docker run --rm -it tutum/dnsutils dig target-host +short host.docker.internal)
    IP=$(echo $IP | rev | cut -c2- | rev)
  else
    IP=$(ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p');
    IP=$(echo $IP | awk '{printf $NF}');
    if ! [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      printf "$red Could not find a valid IP, exiting $end\r\n";
      exit 1;
    fi
  fi
  export HOST_IP="$IP"
  echo "HOST IP: $IP"
fi

if [ "$ENV" == "" ]; then
  ENV='local'
fi

IS_LOCAL=$( ([ "$ENV" == "local" ] || [ "$ENV" == "CI" ]) || echo "false" && echo "true")
DIRR="./"

printf "${grn}Including override env.$end\n";
[ ! -f $DIRR.env.override ] && echo "# Local override env vars." > .env.override || true;
. $DIRR.env.override;

if $IS_LOCAL && [ -f "$DIRR.env.local" ]; then
  printf "${grn}Including local env.$end\n";
  . $DIRR.env.local;
fi

if [ "$ENV" == "CI" ]; then
  printf "${grn}Including ci override env.$end\n";
  . $DIRR.env.override.ci;
fi

printf "${grn}Creating .env with substitutions.$end\n"
. $DIRR.env.dist && envsubst < $DIRR.env.dist > $DIRR.env
envsubst < $DIRR.env > $DIRR.env.tmp && . $DIRR.env.tmp && cp $DIRR.env.tmp $DIRR.env
envsubst < $DIRR.env > $DIRR.env.tmp && . $DIRR.env.tmp && cp $DIRR.env.tmp $DIRR.env
envsubst < $DIRR.env > $DIRR.env.tmp && . $DIRR.env.tmp && cp $DIRR.env.tmp $DIRR.env
. $DIRR.env && rm $DIRR.env.tmp

if $IS_LOCAL && [ -f "$DIRR.env.local" ]; then
  printf "${grn}Adding env present only locally.$end\n"
  printf "\n\n# Local only.\n" >> $DIRR.env
  for var in $(cat $DIRR.env.local | grep -oP "^[^#]*="); do
    envVar=$(cat $DIRR.env.local | grep -oP "^$var.*$");
    cat $DIRR.env | grep "$var" >/dev/null || printf "$envVar\n" >> $DIRR.env;
  done || true;
fi

printf "${grn}Including local non committed overrides.$end\n";
echo "" >> .env
for var in $(cat $DIRR.env.override | grep -o "^[^#]*="); do
  envVar=$(cat $DIRR.env.override | grep -o -m 1 "^$var.*");
  if [ "$(cat $DIRR.env | grep "^$var")" != "" ]; then
    cat $DIRR.env | awk "{gsub(/$var.*/, \"$envVar\")}1" > $DIRR.env.r;
    rm $DIRR.env && mv $DIRR.env.r $DIRR.env;
  else
    echo "$envVar" >> $DIRR.env
  fi
done

envsubst < $DIRR.env > $DIRR.env.tmp && . $DIRR.env.tmp && cp $DIRR.env.tmp $DIRR.env
. $DIRR.env && rm $DIRR.env.tmp

# Make sure docker compose atleast exists.
[ ! -f docker-compose.override.yaml ] \
  && printf "${grn}Adding local override docker compose file.$end\n" \
  && echo "version: \"3.5\"" > docker-compose.override.yaml ;\

if $IS_LOCAL; then
  printf "${grn}Creating env substituted nginx configurations.$end\n";
  for f in ${DIRR}docker/site-*.conf; do
    envsubst < $f > $f.local
    sed -i -e 's/§/$/g' $f.local
  done
fi

printf "${grn}Creating .env.test with substitutions.$end\n"
. $DIRR.env.dist.test && envsubst < $DIRR.env.dist > $DIRR.env.test
envsubst < $DIRR.env > $DIRR.env.tmp && . $DIRR.env.tmp && cp $DIRR.env.tmp $DIRR.env.test
envsubst < $DIRR.env > $DIRR.env.tmp && . $DIRR.env.tmp && cp $DIRR.env.tmp $DIRR.env.test
envsubst < $DIRR.env > $DIRR.env.tmp && . $DIRR.env.tmp && cp $DIRR.env.tmp $DIRR.env.test
rm .env.tmp
for var in $(cat $DIRR.env.dist.test | grep -o "^[^#]*="); do
  envVar=$(cat $DIRR.env.dist.test | grep -o -m 1 "$var.*");
  if [ "$(cat $DIRR.env.test | grep "^$var")" != "" ]; then
    cat $DIRR.env.test | awk "{gsub(/$var.*/, \"$envVar\")}1" > $DIRR.env.r;
    rm $DIRR.env.test && mv $DIRR.env.r $DIRR.env.test;
  else
    echo "$envVar" >> $DIRR.env.test
  fi
done

if $IS_LOCAL; then
  printf "$yel\nAdd the following to hosts file!$end\n";
  for host in $(cat $DIRR.env | sed -n -e 's/^[^=]*_HOST=\(.*\)/\1/p'); do
    printf '0.0.0.0 %s\n' "$host";
  done
  printf "\n\n"
fi