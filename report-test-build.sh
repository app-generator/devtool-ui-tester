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

      echo "x) TESTS for ${repoDir} / ${command} / NodeJS-${NODE_VERSION}" >> $report_file 
      echo ' '                                                             >> $report_file

      # save_report $report_file ERR 
      # exit 1

      PIPELINE_ERROR_MESSAGE="Node version $NODE_VERSION, $command -> failed"
      NPM_STATUS=False
      YARN_STATUS=False

      echo "Installing dependencies with $command"
        if $command install; then
            echo " > success Installed $command"          >> $report_file
        else
            echo " > error Installation failed $command"  >> $report_file
            echo " > error $PIPELINE_ERROR_MESSAGE"       >> $report_file 
            save_report $report_file ERR
            exit 1
        fi
      echo " > Running test with $command"
        if CI=true $command test --passWithNoTests; then
            echo " >  success Tests passed $command"      >> $report_file
        else
            echo " > error Tests failed $command"         >> $report_file
            echo " > error $PIPELINE_ERROR_MESSAGE"       >> $report_file 
            save_report $report_file ERR           
            exit 1
        fi
      echo "Running build with $command"
        if [ "$command" = "npm" ]; then
            if $command run build; then
                echo " > success Built $command"          >> $report_file
            else
                echo " > error Build failed $command"     >> $report_file  
                echo " > error $PIPELINE_ERROR_MESSAGE"   >> $report_file 
                save_report $report_file ERR
                exit 1
            fi
        else 
            if $command build; then
                echo " > success Built $command"          >> $report_file 
            else
                echo " > error Build failed $command"     >> $report_file 
                echo " > error $PIPELINE_ERROR_MESSAGE"   >> $report_file 
                save_report $report_file ERR
                exit 1
            fi
        fi

        if [ "$command" = "npm" ]; then
            npm i -g serve
        else
            yarn add serve
        fi

        echo "Starting APP in browser"                            >> $report_file 
        if serve -s build & 
        then
            echo " > Serving application with $command"           >> $report_file

            chromium-browser --headless --screenshot=$report_sshot "http://localhost:3000"
            mv $report_sshot ../reports/

            echo " > Saving SSHot -> $report_sshot"               >> $report_file

            # not working    
            #echo "test body" | mail -s 'test subject' chirilovadrian@gmail.com 

        else
            echo " > error $repoDir Starting APP failed $command" >> $report_file   
            echo " > error $PIPELINE_ERROR_MESSAGE"               >> $report_file 
            save_report $report_file ERR
            exit 1
        fi

        killall -9 node

        save_report $report_file OK        

    done

    # Iterate on the next REPO    
    cd ..

 done 

 # All good ..
 exit 0
