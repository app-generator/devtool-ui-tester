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

declare -a COMPILERS=( "yarn" ) # "npm" "yarn"

echo "Starting compatibily test"

readarray -t repoArrays < <(jq -c '.repositories[]' repositories.json) # Reads the repositories from the json file 

for repo in "${repoArrays[@]}"; do

    repoURL=$(echo $repo | jq '.repoURL' | sed 's/\"//g') # Cleaning the repoURL JSON output
    repoDir=$(basename $repoURL .git) # Getting the repo directory name

    # Using node commands: npm and yarn

    for command in "${COMPILERS[@]}"; do

        # Build SSHot and report file name
      
        report_file="${repoDir}-${command}-node-${NODE_VERSION}-STATUS_NA.log"
        report_sshot="${repoDir}-${command}-node-${NODE_VERSION}-sshot.png"
        report_BASE="./reports"

        # File creation    
        echo ' ' > $report_BASE/$report_file

        echo "START TESTS for ${repoDir} / ${command} / NodeJS-${NODE_VERSION}" >> $report_BASE/$report_file 
        echo ' '                                                                >> $report_BASE/$report_file

        # Force removal for each compiler
        echo " > Force REMOVAL $repoDir"    >> $report_BASE/$report_file
        rm -rf $repoDir
        echo "   ...ok"                      >> $report_BASE/$report_file

        echo " > Cloning $repoURL"          >> $report_BASE/$report_file   
        if git clone $repoURL; then
            echo "   ...ok"                  >> $report_BASE/$report_file
        else
            echo "   ...err"                 >> $report_BASE/$report_file
            save_report $report_BASE/$report_file ERR
            exit 1
        fi

        # !!! NEW Directory !!! 
        cd $(basename $repoURL .git)
        report_BASE="../reports"

        echo " > [$command] Install modules " >> $report_BASE/$report_file
        if $command install; then
            echo "   ...ok"                   >> $report_BASE/$report_file
        else
            echo "   ...err"                  >> $report_BASE/$report_file
            save_report $report_BASE/$report_file ERR
            continue
        fi
      
        # Disable product tests
        #echo " > [$command] Running tests "   >> $report_BASE/$report_file
        #if CI=true $command test --passWithNoTests; then
        #    echo "   ...ok"                   >> $report_BASE/$report_file
        #else
        #    echo "   ...err"                  >> $report_BASE/$report_file
        #    save_report $report_BASE/$report_file ERR           
        #    continue
        #fi

        echo " > [$command] Compile Sources " >> $report_BASE/$report_file
        if [ "$command" = "npm" ]; then
            if $command run build; then
                echo "   ...ok"               >> $report_BASE/$report_file
            else
                echo "   ...err"              >> $report_BASE/$report_file
                save_report $report_BASE/$report_file ERR
                continue
            fi
        else 
            if $command build; then
                echo "   ...ok"                >> $report_BASE/$report_file
            else
                echo "   ...err"               >> $report_BASE/$report_file
                save_report $report_BASE/$report_file ERR
                continue
            fi
        fi

        echo " > Install serve utility "     >> $report_BASE/$report_file
        if [ "$command" = "npm" ]; then
            npm i -g serve
            echo "   ...ok (via NPM)"          >> $report_BASE/$report_file
        else
            yarn global add serve
            echo "   ...ok (via YARN)"         >> $report_BASE/$report_file
        fi

        echo " > [$command] Starting APP in browser" >> $report_BASE/$report_file
        if serve -s build & 
        then
            echo "   ...ok" >> $report_BASE/$report_file

            echo " > Saving SSHot -> $report_sshot" >> $report_BASE/$report_file

            chromium-browser --headless --screenshot=$report_sshot "http://localhost:3000" 
            mv $report_sshot ../reports/

            echo "   ...ok" >> $report_BASE/$report_file

        else
            echo "   ...err" >> $report_BASE/$report_file
            save_report $report_BASE/$report_file ERR
            continue
        fi

        killall -9 node

        save_report $report_BASE/$report_file OK    

        # Iterate on the next REPO    
        cd ..    

    done

 done 

 # All good ..
 exit 0
