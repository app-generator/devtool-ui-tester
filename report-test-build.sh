#! /bin/bash

# Defining function to print error or success message

print_message() {
    type=$1
    message=$2
    if [ $type == "error" ]; then
        echo -e "\e[31m$message\e[0m" 
    else
        echo -e "\e[32m$message\e[0m"
    fi
}

save_report() {

    report_file=$1
    status=$2

    echo ' ' >> $report_file

    if [ "$status" = "OK" ]; then 

        echo "END tests, STATUS=OK" >> $report_file

    else

        echo "END tests, STATUS=ERR" >> $report_file
    fi

    output_file="${report_file/STATUS_NA/"STATUS_$status"}"
    mv $report_file $output_file

    # Update master report file
    # echo "$status - " "${output_file/../reports/""}" >> ../reports/report.txt
} 

NODE_VERSION=$(node --version)

declare -a NODE_COMMANDS=("npm") # Default ("yarn" "npm") 

echo "Starting compatibily test"

readarray -t repoArrays < <(jq -c '.repositories[]' repositories.json) # Reads the repositories from the json file 

for repo in "${repoArrays[@]}"; do

   #echo '=============================' >> reports/log.txt
   #echo '*** *** *** START *** *** ***' >> reports/log.txt
   #echo ' ' >> reports/log.txt

   repoURL=$(echo $repo | jq '.repoURL' | sed 's/\"//g') # Cleaning the repoURL JSON output
   repoDir=$(basename $repoURL .git) # Getting the repo directory name

   #sshot_name="${repoDir}-${command}-node-${NODE_VERSION}-chrome.png"
   #sshot_name="screen.png"

   echo "Cloning $repoURL"
   if git clone $repoURL; then
     echo "Cloned $repoURL"             # >> reports/log.txt
   else
     echo "Failed to clone $repoURL"    # >> reports/log.txt
     echo ' '                           # >> reports/log.txt
     echo "END test, STATUS= FAILED"    # >> reports/log.txt
     exit 1
     #continue
   fi

   # Accessing the cloned repository directory
   cd $(basename $repoURL .git)
    
   # Using node commands: npm and yarn

    for command in "${NODE_COMMANDS[@]}"; do

        # Build SSHot and report file name
      
        report_file=../reports/"${repoDir}-${command}-node-${NODE_VERSION}-STATUS_NA.log"
        report_sshot="${repoDir}-${command}-node-${NODE_VERSION}-sshot.png"

        echo "START TESTS for ${repoDir} / ${command} / NodeJS-${NODE_VERSION}" >> $report_file 
        echo ' '                                                                >> $report_file

        NPM_STATUS=False
        YARN_STATUS=False

        echo " > [$command] Install modules " >> $report_file
        if $command install; then
            echo "   ...ok" >> $report_file
        else
            echo "   ...err" >> $report_file
            save_report $report_file ERR
            continue
        fi
      
        echo " > [$command] Running tests " >> $report_file
        if CI=true $command test --passWithNoTests; then
            echo "   ...ok" >> $report_file
        else
            echo "   ...err" >> $report_file
            save_report $report_file ERR           
            continue
        fi

        echo " > [$command] Compile Sources " >> $report_file
        if [ "$command" = "npm" ]; then
            if $command run build; then
                echo "   ...ok" >> $report_file
            else
                echo "   ...err" >> $report_file
                save_report $report_file ERR
                continue
            fi
        else 
            if $command build; then
                echo "   ...ok" >> $report_file
            else
                echo "   ...err" >> $report_file
                save_report $report_file ERR
                continue
            fi
        fi

        echo " > Install `serve` utility " >> $report_file
        if [ "$command" = "npm" ]; then
            npm i -g serve
        else
            yarn add serve
        fi

        echo " > [$command] Starting APP in browser" >> $report_file 
        if serve -s build & 
        then
            echo "   ...ok" >> $report_file

            echo " > Saving SSHot -> $report_sshot" >> $report_file

            chromium-browser --headless --screenshot=$report_sshot "http://localhost:3000"
            mv $report_sshot ../reports/

            echo "   ...ok" >> $report_file

        else
            echo "   ...err" >> $report_file
            save_report $report_file ERR
            continue
        fi

        killall -9 node

        save_report $report_file OK        

    done

    # Iterate on the next REPO    
    cd ..

 done 

 # All good ..
 exit 0
