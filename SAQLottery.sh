#!/bin/bash

function validate_env(){
  if [ -z "$discord_webhook_url" ]; then
    echo "Missing discord_webhook_url environment variable"
    exit
  fi
}

validate_env
echo "Checking open lottery..."

# Generalized Discord Notification Script. source: https://gist.github.com/apfzvd/300346dae55190e022ee49a1001d26af
# Define a function to send a message
send_discord_notification() {
  local message=$1
  # Construct payload
  local payload=$(cat <<EOF
{
  "content": "$message"
}
EOF
)
  # Send POST request to Discord Webhook
  curl -H "Content-Type: application/json" -X POST -d "$payload" $discord_webhook_url
}


#Read last href
old_href="tmp"
if [ -e href ]; then
  old_href=$(cat href)
fi
#echo "old:$old_href"

# Grab lottery page
rm lottery.html
curl -s https://www.saq.com/en/new-products/lottery -o lottery.html

new_href=$(xmllint --html --nowarning --xpath "/html/body/div[3]/div[2]/div[1]/div[4]/div/div/div[3]/div/div[1]/div/div[1]/div[2]/div/a/@href" lottery.html 2>/dev/null)
#echo "new:$new_href"

data_pb_style=$(xmllint --html --nowarning --xpath "/html/body/div[3]/div[2]/div[1]/div[4]/div/div/div[3]/div/div[1]/div/div[1]/div[2]/@data-pb-style" lottery.html 2>/dev/null)
class=$(echo ${data_pb_style}| cut -d'"' -f 2)
#echo "class:$class"
regex_cmd="html-body \[data-pb-style=${class}\]{.*?}"
style=$(grep -o -m1 -P "${regex_cmd}" lottery.html)
#echo "style:$style"

visible=0
if [[ $style != *"display:none"* ]]; then
  echo "Button is visible."
  visible=1
fi

href_diff=0
if [ "$new_href" != "$old_href" ]; then
  echo "Link is different."
  href_diff=1
fi

opening_date=$(xmllint --html --nowarning --xpath "/html/body/div[3]/div[2]/div[1]/div[4]/div/div/div[3]/div/div[1]/div/div[1]/div[1]/p/strong/text()" lottery.html 2>/dev/null)
#echo "opening_date:$opening_date"

if [ ! ${#opening_date} -gt 5 ]; then
  echo "no date meaning it's already open"
  opening_date=$(date '+%Y-%m-%d')
fi

opening_epoch=$(date -d "${opening_date} +8 hours" +"%s" 2>/dev/null)
if [ $? -ne 0 ]; then
  #Invalid date, assume it's far in the future
  future_date=$(date '+%Y-%m-%d' -d'1 year')
  opening_epoch=$(date -d "${future_date} +8 hours" +"%s")
#  echo "opening_epoch:$opening_epoch"
fi

timestamp=$(date +'%s')

lottery_open=0
if [[ $timestamp -ge $opening_epoch ]]; then
  echo "Lottery date is in the past."
  lottery_open=1
fi

if [ $href_diff == 1 ] && [ $lottery_open == 1 ] && [ $visible == 1 ]; then
  echo "Sending Discord notification"
#  send_discord_notification "New lottery is open!"
  parsed_href=$(echo "$new_href" | sed 's/.*="\(.*\)"/\1/')
  send_discord_notification "SAQ lottery is open!\nhttps://www.saq.com${parsed_href}\n@everyone"
  echo "$new_href" > href
fi

echo "Done checking open lottery."
