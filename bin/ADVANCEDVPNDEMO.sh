#!/bin/sh

# This file will contain commands to deploy the cloudformation template for s3 and the relevant commands to host a static website.

cloudformationstackactions() {

    # Help function as an overview of the capabilities of the script
    help() {
        printf "\n%s\n%s\n%s\n%s\n%s" "Here are the various flags supported by the script" \
            "To validate the template, use flag \"-v\"" \
            "To deploy the template, use flag \"-d\"" \
            "To delete the stack (and associated resources), use flag \"-D\"" \
            "To retain the log of the process in a file (mention file as argument after flag), use flag \"-l\""
    }

    # Invoke the "help" function when used without flags and arguments
    if [ $# -eq 0 ]; then
        help
        return
    fi

    # Logic for the flags

    validate_template=0     # -v
    deploy_template=0       # -d
    delete_stack=0          # -D
    change_stack_name=0     # -S
    retain_log=0            # -l

    # In this case, order of commands is very important, as I won't be able to push objects to a bucket without deploying the stack first,
    # Neither will I be able to delete the stack without emptying the bucket first.
    # The arguments are parsed in the ORDER OF THE CASE STATEMENTS/the order in the which ${opts} is defined

    while getopts "vdupDSlh" opts
    do
        case ${opts} in
            v)
                validate_template=1
                ;;
            d)
                deploy_template=1
                ;;
            D)
                delete_stack=1
                ;;
            S)
                change_stack_name=1
                ;;
            l)
                retain_log=1
                ;;
            h)
                help
                return
                ;;
            \?)
                printf "\n%s" "Invalid character. Exiting..."
                return
                ;;
            *)
                printf "\n%s" "Sorry, wrong argument"
                return
                ;;
        esac
    done

# -----------------------
# Basic variables:

    profile=""
    region_name=""

    if [ "${change_stack_name}" = 1 ]; then
        # Get the argument specified (the logic is that the word required will be the last argument)
        word="$(for list in "$@"; do : ; done ; printf "%s" "${list}")"
        stack_name="${word}"
    else
        stack_name="ADVANCEDVPNDEMO"
    fi

    logfile="logfile"

# ---------------------
# Template(s) to run

    template="../src/BGPVPNINFRA.yaml"
    template_body="file://${template}"

# --------------------
# Required IAM capability

    capabilities="CAPABILITY_NAMED_IAM"

#
# --------------------
# Begin logic


# --------------------
# Validate template

    if [ "${validate_template}" = 1 ]; then

        # To validate the template
        aws cloudformation validate-template --region "${region_name}" --template-body "${template_body}" --profile "${profile}"
    fi

# --------------------
# Deploy Template

    if [ "${deploy_template}" = 1 ]; then

        # To deploy the stack
        aws cloudformation deploy --template "${template}" --stack-name "${stack_name}" --region "${region_name}" --profile "${profile}" --capabilities "${capabilities}"

    fi

# --------------------
# Delete all resources

    if [ "${delete_stack}" = 1 ]; then

        # Delete backend-stack
        aws cloudformation delete-stack --stack-name "${stack_name}" --region "${region_name}" --profile "${profile}"
    fi

# --------------------
# Retain logs

    if [  "${retain_log}" = 1 ]; then

        # Write events to file (mentioned as argument)
        aws cloudformation describe-stack-events --stack-name "${stack_name}" --region "${region_name}" --profile "${profile}" >> "${logfile}"
    fi
}

cloudformationstackactions "$@"
