#!/bin/bash

################################################################################
# Module Name: DNS Checker                                                     #
# Contributors: Casey M. & Elijah S.                                           #
# Description: DNS Information for an arbitrary number of domains.             #
# Required Packages: bind-utils
################################################################################

# Sourcing Triton & libraries
source /dev/stdin <<<"$(< <(curl -ks https://codesilo.dimenoc.com/caseym/triton/raw/master/loader))"
include format.shl
include stylize.shl
include net.shl

# Status Column Variables
readonly colorGreen="$(stylize -c green -b)"
readonly colorYellow="$(stylize -c yellow -b)"
readonly colorRed="$(stylize -c red -b)"

# Global Variables
IFS=$'\n'
declare -a rootLevel=(d.root-servers.net a.root-servers.net b.root-servers.net c.root-servers.net k.root-servers.net m.root-servers.net)

################################################################################
# Name: main()                                                                 #
# Description: Primary function for module                                     #
# Options: none                                                                #
# Dependencies:                                                                #
# * format.shl::init_table()                                                   #
# * format.shl::print_table()                                                  #
# * format.shl::add_row()                                                      #
# * stylize.shl::stylize()                                                     #
################################################################################

function main(){

  # Confirm Domain Variable Included
  if (( "${#@}" == 0 ))
  then
    printf "${colorYellow}Please provide domains as arguments.$(stylize -r)\n"
    return 1
  fi

  # Confirm Bind-Utils Package Installed
  if ! is_command "dig"
  then
    printf "${colorRed}dig is not available.$(stylize -r)\n"
    return 1
  fi

  # Process Domain(s)
  for domain in "$@"
  do

    # Filter Domain Variable
    domain="${domain#http*://*}"
    domain="${domain#www.*}"
    domain="${domain%%/*}"
    domain="${domain#*@}"
    domain="${domain,,}"

    # Create Table & Header Row
    #init_table --class minimal -M 140 "Domain: $domain"
    init_table -M 140 "Domain: $domain"
    add_row -t "$(stylize -c white -b)" "" "Type" "Notes" "From" "Record" "Value"

    # Reset CNAME
    cname_found="false"
    CNAME_R=()
    CNAME_V=()
    printf "Grabbing DNS records...\n"

    # CNAME Checker
    while read -r line
    do
      cname_found="true"
      CNAME_R+=($(awk '{print $1}' <<< "$line"))
      CNAME_V+=($(awk '{print $(NF)}' <<< "$line"))
    done< <(dig +noall +answer "$domain" | awk 'NR == 1 {if ($4 ~ /CNAME/ && length(cname)==0) {cname="true"}};{if (cname == "true") {print $0}}')

    # Alternate Data Collection (No CNAME) Phase
    if ! "$cname_found"
    then
      IP=($(dig +short $domain | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}'))
      NS=($(dig +short NS $domain))
    fi

    # Primary Data Collection Phase
    WWWA=($(dig +short www.$domain | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}'))
    MAILA=($(dig +short mail.$domain | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}'))
    MX=($(dig +short MX $domain | awk '{print $2}'))
    TXT=($(dig +short TXT $domain))
    AAAA=($(dig +noall +answer AAAA $domain | awk '{if ($4 ~ /AAAA/) {print $5}}'))
    DKIM="$(dig +short TXT default._domainkey.$domain)"
    DMARC="$(dig +short TXT _dmarc.$domain)"
    SOA=$(dig +noall +answer SOA $domain | awk '{if ($4 ~ /SOA/) {print $5,$6}}')
    DNSSEC="$(dig +noall +sigchase $domain | tac | awk 'FNR==2 {print $(NF)}')"
    DNSSEC_COUNT=$(dig +noall +answer RRSIG $domain | wc -l)

    # Move the cursor up a line.
    printf "%b" "\e[1A"

    # Delete the line
    tput ed

    # DNS Table Output - NOT FOUND
    if dns_check
    then
      if (( __TBL_ROW_COUNT == 1 ))
      then
        add_row -c 1 -T "$colorRed" "[!!]" "-" "No records found" "-" "-" "-"
        print_table
        printf "\n"
      else
        print_table
        printf "\n"
      fi
    else
      add_row -c 1 -T "$colorRed" "[!!]" "-" "No root TLD found" "-" "-" "-"
      print_table
      printf "\n"
    fi
  done
  
  return 0

}

################################################################################
# Name: dns_check()                                                            #
# Description: Primary function for module                                     #
# Options: none                                                                #
# Dependencies:                                                                #
# * format.shl::init_table()                                                   #
# * format.shl::print_table()                                                  #
# * format.shl::add_row()                                                      #
# * stylize.shl::stylize()                                                     #
################################################################################

function dns_check(){

  checking "A"
    for address in "${IP[@]}"
    do
      if [[ "$(whois_info "$address" 2>/dev/null | grep -qi HostDime ; echo $?)" == 0 ]]
      then
        add_row -c 1 -T "$OK" "[OK]" "A" "Internal" "DNS" "-" "$address"
      else
        add_row -c 1 -T "$NO" "[!!]" "A" "External" "DNS" "-" "$address"
      fi
    done

  checking "CNAME"
  for ((i=0; i < "${#CNAME_R[@]}";i++))
  do
    if ! is_ip "${CNAME_V[$i]}"
    then
      add_row -c 1 -T "$NOTE" "[??]" "CNAME" "-" "DNS" "${CNAME_R[$i]}" "${CNAME_V[$i]}"
    else
      if [[ "$(whois_info "${CNAME_V[$i]}" 2>/dev/null | grep -qi HostDime ; echo $?)" == 0 ]]
      then
        add_row -c 1 -T "$OK" "[OK]" "A" "Internal" "DNS" "${CNAME_R[$i]}" "${CNAME_V[$i]}"
      else
        add_row -c 1 -T "$NO" "[!!]" "A" "External" "DNS" "${CNAME_R[$i]}" "${CNAME_V[$i]}"
      fi
    fi
  done

  for address in "${WWWA[@]}"
  do
    if [[ "$(whois_info "$address" 2>/dev/null | grep -qi HostDime ; echo $?)" == 0 ]]
    then
      add_row -c 1 -T "$OK" "[OK]" "A" "Internal" "DNS" "www.$domain" "$address"
    else
      add_row -c 1 -T "$NO" "[!!]" "A" "External" "DNS" "www.$domain" "$address"
    fi
  done

  for address in "${MAILA[@]}"
  do
    if [[ "$(whois_info "$address" 2>/dev/null | grep -qi HostDime ; echo $?)" == 0 ]]
    then
      add_row -c 1 -T "$OK" "[OK]" "A" "Internal" "DNS" "mail.$domain" "$address"
    else
      add_row -c 1 -T "$NO" "[!!]" "A" "External" "DNS" "mail.$domain" "$address"
    fi
  done

  checking "AAAA"
  for address in "${AAAA[@]}"
  do
    if [[ "$(whois_info "$address" 2>/dev/null | grep -qi HostDime ; echo $?)" == 0 ]]
    then
      add_row -c 1 -T "$NOTE" "[!!]" "AAAA" "Internal" "DNS" "-" "$address"
    else
      add_row -c 1 -T "$NO" "[!!]" "AAAA" "External" "DNS" "-" "$address"
    fi
  done

  checking "MX"
  for mail in "${MX[@]}"
  do
    # Some MX records will be multiple IPs or a CNAME.
    # We need to account for that otherwise, whois  will error out.
    IPARR=($(dig +short "$mail" | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}'))
    # Limit the checks to 4 IPs.
    # Some hosts may have ~14+ IPs as seen with assuregreenlawn.com
    ARR=($(for IP in "${IPARR[@]::4}"; do whois_info "$IP" 2>/dev/null | grep -m1 -iq HostDime;echo $?;done))
    if [[ "${ARR[@]}" =~ "^(0 )*0$" || "${ARR[@]}" =~ "0" ]]
    then
      add_row -c 1 -T "$OK" "[OK]" "MX" "Internal" "DNS" "-" "$mail ($(printf "%s " "${IPARR[@]::4}" | sed 's/[[:blank:]]*$//'))"
    else
      add_row -c 1 -T "$NO" "[!!]" "MX" "External" "DNS" "-" "$mail ($(printf "%s " "${IPARR[@]::4}" | sed 's/[[:blank:]]*$//'))"
    fi
  done

  checking "DKIM"
  if is_not_empty "$DKIM"
  then
    add_row -c 1 -T "$NOTE" "[??]" "DKIM" "-" "DNS" "-" "Found"
  fi

  checking "DMARC"
  if is_not_empty "$DMARC"
  then
    add_row -c 1 -T "$NOTE" "[??]" "DMARC" "-" "DNS" "-" "Found"
  fi

  checking "TXT"
  for text in "${TXT[@]}"
  do
    add_row -c 1 -T "$NOTE" "[??]" "TXT" "-" "DNS" "-" "$text"
  done

  checking "PTR"
  for address in "${IP[@]}"
  do
    PTR=($(dig +short -x $address))
    if (( "${#PTR[@]}" != 0 ))
    then
      add_row -c 1 -T "$NOTE" "[??]" "PTR" "-" "DNS" "$address" "$(echo ${PTR[@]} | tr '\n' ' ')"
    fi
  done

  checking "SOA"
  if is_not_empty "$SOA"
  then
    add_row -c 1 -T "$NOTE" "[??]" "SOA" "-" "DNS" "-" "$SOA"
  fi

  checking "DNSSEC"
  if [[ "$DNSSEC" == "SUCCESS" ]]
  then
    add_row -c 1 -T "$OK" "[OK]" "RRSIG" "Validation" "DNS" "-" "$DNSSEC"
  elif (( DNSSEC_COUNT > 0 ))
  then
    add_row -c 1 -T "$NO" "[!!]" "RRSIG" "Validation" "DNS" "-" "$DNSSEC"
  fi

  checking "NS"
  for nameserver in "${NS[@]}"
  do
    # If an NS record has multiple IPs, we need to check each one individually.
    # Otherwise, whois will have issues checking.
    IPARR=($(dig +short "$nameserver"))
    ARR=($( for IP in "${IPARR[@]}"; do whois_info "$IP" 2>/dev/null | grep -m1 -iq HostDime;echo $?;done))
    if [[ "${ARR[@]}" =~ "^(0 )*0$" || "${ARR[@]}" =~ "0" ]]
    then
      add_row -c 1 -T "$OK" "[OK]" "NS" "Internal" "DNS" "$nameserver" "$(printf "%s " "${IPARR[@]::4}" | sed 's/[[:blank:]]*$//')"
    else
      add_row -c 1 -T "$NO" "[!!]" "NS" "External" "DNS" "$nameserver" "$(printf "%s " "${IPARR[@]::4}" | sed 's/[[:blank:]]*$//')"
    fi
  done

  checking "Registrar NS"
  index="$[$RANDOM % ${#rootLevel[@]}]"
  rootTLD=($(dig +noall +additional "$domain" @"${rootLevel[$index]}" | awk '{if ($4 == "A") {print $1}}'))
  if (( "${#rootTLD[@]}" == 0 ))
  then
    printf "\r\e[0K"
    return 3
  fi
  index="$[$RANDOM % ${#rootTLD[@]}]"

  local custom=0
  declare -a RNS
  declare -a RNSIP
  while read -r line
  do
    RNS+=($(awk '{print $1}' <<< "$line"))
    RNSIP+=($(awk '{print $2}' <<< "$line"))
  done < <(dig +noall +additional "$domain" @"${rootTLD[$index]}"  | awk '{if ($4 == "A") {print $1,$NF}}')
  for ((i=0; i < "${#RNS[@]}"; i++))
  do
    add_row -c 1 -T "$NOTE" "[??]" "NS" "Registrar" "TLD DNS" "${RNS[$i]}" "${RNSIP[$i]}"
    custom=1
  done

  if (( custom == 0 ))
  then
    NS=($(dig +noall +authority "$domain" @"${rootTLD[$index]}"  | awk '{if ($4 == "NS") {print $NF}}'))
    for nameserver in "${NS[@]}"
    do
      add_row -c 1 -T "$NOTE" "[??]" "NS" "Registrar" "TLD DNS" "$nameserver" "-"
      custom=1
    done
  fi

  printf "\r\e[0K"
  return 0
}

#****************************************************
# checking() - Simple wrapper for a printf statement.
#
# Options:
# None
#
# Dependencies:
# * None
#****************************************************
function checking()
{
  # Print a carriage-return and deletes to the end of line (overwriting)
  printf "\r\e[0KChecking %s Records..." "$1"

  return 0
}

main "$@"
