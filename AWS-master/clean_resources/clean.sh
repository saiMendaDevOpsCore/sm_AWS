#!/bin/bash -x


# Author : raghuk.vit@gmail.com , harsha2006@gmail.com
# Purpose:
# Script purpose is to list all the resources which are been created in AWS Account for all regions.

curl -s https://raw.githubusercontent.com/linuxautomations/scripts/master/common-functions.sh >/tmp/common-functions.sh
source /tmp/common-functions.sh

### Check AWS CLI Installed or not.
pip list 2>/dev/null| grep -w awscli &>/dev/null
if [ $? -ne 0 ]; then 
	error "AWSCLI not installed"
	hint "Run the following URL to setup AWSCLI"
	hint ""
	exit 1
fi

### Checking AWS Credentials.
if [ -z "$ACCESS_ID" -o -z "$ACCESS_KEY" ]; then 
	error "AWS Credentials are not set".
	info "Setup the AWS Access Keys as follows and then run the script"
	hint "export ACCESS_ID=<YOUR ACCESS ID> ; export ACCESS_KEY=<YOUR ACCESS KEY>"
	exit 1
fi

export AWS_ACCESS_KEY_ID=$ACCESS_ID ; export AWS_SECRET_ACCESS_KEY=$ACCESS_KEY
### Setting up AWS CLI 
REGIONS=(us-east-2 us-east-1 us-west-1 us-west-2 ca-central-1 ap-south-1 ap-northeast-2 ap-southeast-1 ap-southeast-2 ap-northeast-1 eu-central-1 eu-west-1 eu-west-2 sa-east-1)
SERVICES=(EC2 S3 ELASTIC_BEANSTALK RDS CODECOMMIT CODEBUILD CODEDEPLOY CODE_PIPELINE CLOUDWATCH SNS)

Check_EC2() {
	
	if [ -n "$ACTION" ]; then 
		VMS=(`aws ec2 describe-instances --region $1 --output table | grep InstanceId | awk '{print $(NF-1)}'`)
		for VM in ${VMS[*]}; do
			aws ec2 terminate-instances --instance-ids $VM --region $1 &>/dev/null 
			PRINT $VM
		done
	return
	fi
	count=$(aws ec2 describe-instances --region $1 --output table | grep InstanceId | wc -l)
	count1=$(aws ec2 describe-volumes --region $1 --output table  | grep us-east-2 | wc -l)
	if [ $count -gt 0 -o $count1 -gt 0 ]; then 
		echo -e "\e[31m$1,$count+$count1\e[0m" >>$FILE
	else
		echo "$1,$count+$count1" >>$FILE
	fi
}

Check_S3() {
	count=$(aws s3 ls | wc -l)
	info "\t\t Number of S3 Buckets = \e[31m $count"
}

Check_EB() {
	if [ -n "$ACTION" ]; then 
		EBS=(`aws elasticbeanstalk  describe-applications --region $1 --output table | grep ApplicationName | awk -F '|' '{print $4}'`)
		for APP in ${EBS[*]}; do
			aws elasticbeanstalk delete-application --application-name $APP --region $1 &>/dev/null 
			PRINT $APP
		done
	return
	fi
	count=$(aws elasticbeanstalk  describe-applications  --region $1 | grep ApplicationName | wc -l)
	echo "$1,$count" >>$FILE
}

Check_RDS() {
	if [ -n "$ACTION" ]; then
		RDS=(`aws rds describe-db-instances --region $1 --output table| grep DbiResourceId | awk -F '|' '{print $4}'`)
		for RD in ${RDS[*]}; do 
			aws rds delete-db-instance --db-instance-identifier $RD --region $1 &>/dev/null
			PRINT $RD
		done
	return
	fi
	count=$(aws rds describe-db-instances --region $1 | grep DbiResourceId | wc -l)
	echo "$1,$count" >>$FILE
}

Check_CC() {
	if [ -n "$ACTION" ]; then
		CCS=(`aws codecommit list-repositories  --region us-east-2 --output text | awk '{print $3}'`)
		for CC in ${CCS[*]}; do 
			aws codecommit delete-repository --repository-name $CC --region $1 &>/dev/null
			PRINT $CC
		done
	return
	fi
	count=$(aws codecommit list-repositories  --region $1 --output table | grep repositoryName | wc -l)
	echo "$1,$count" >>$FILE
}

Check_CB() {
	if [ -n "$ACTION" ]; then
		CBS=(`aws codebuild list-projects --region $1 --output text | awk '{print $2}'`)
		for CB in ${CBS[*]}; do 
			aws codebuild  delete-project --name $CB --region $1 &>/dev/null
			PRINT $CB
		done
	return
	fi
	count=$(aws codebuild list-projects --region $1 --output text 2>/dev/null| wc -l)
	echo "$1,$count" >>$FILE
}

Check_CD() {
	if [ -n "$ACTION" ]; then
		CDS=(`aws deploy list-applications --region $1 --output text  | awk '{print $2}'`)
		for CD in ${CDS[*]}; do 
			aws deploy delete-application --application-name $CD --region $1 &>/dev/null
			PRINT $CD
		done
	return
	fi
	count=$(aws deploy list-applications --region $1 --output text | wc -l )
	echo "$1,$count" >>$FILE
}

Check_CP() {
	if [ -n "$ACTION" ]; then
		CPS=(`aws codepipeline list-pipelines --region $1 --output text  | awk '{print $3}'`)
		for CP in ${CPS[*]}; do 
			aws codepipeline delete-pipeline --name $CP --region $1 &>/dev/null
			PRINT $CP
		done
	return
	fi
	count=$(aws codepipeline list-pipelines --region $1 --output text | wc -l )
	echo "$1,$count" >>$FILE
}

Check_CW() {
	if [ -n "$ACTION" ]; then
		CWS=(`aws cloudwatch describe-alarms --region us-east-2 --output table | grep AlarmName| awk -F '|' '{print $4}'`)
		for CW in ${CWS[*]}; do 
			aws cloudwatch delete-alarms --alarm-names $CW --region $1 &>/dev/null
			PRINT $CW
		done
	return
	fi
	count=$(aws cloudwatch describe-alarms --region $1 --output table | grep AlarmArn | wc -l )
	echo "$1,$count" >>$FILE
}

Check_SNS() {
	if [ -n "$ACTION" ]; then
		SNS=(`aws sns list-topics  --region $1 --output text | awk '{print $NF}'`)
		for SN in ${SNS[*]}; do 
			aws sns delete-topic --topic-arn $SN &>/dev/null
			PRINT $SN
		done
	return
	fi
	count=$(aws sns list-topics  --region $1 --output text |  wc -l )
	echo "$1,$count" >>$FILE
}

headfoot() {
	a=$1
	a=$(($a-2))
	BORDER=$(while [ $a -gt 1 ]; do echo -n "-" ; a=$(($a-1));done ;echo)
	BORDER=$(echo $BORDER |sed -e 's/^/+/' -e 's/$/+/')
}

PRINT() {
	if [ -z "$1" ]; then 
		echo -e "$(cat $FILE | awk -F , '{print $1}'|xargs|sed -e 's/ /,/g')\n$(cat $FILE | awk -F , '{print $2}'|xargs|sed -e 's/ /,/g')" | csvlook --no-inference >$FILE.o 
		c=$(cat $FILE.o| head -1|wc -c)
		headfoot "$c"
		sed -i -e "1 i $BORDER" -e "$ a $BORDER" $FILE.o
		cat $FILE.o
	else
		echo -e "Removed $SERVICE resource in $REGION\t-\t$1" | column -t
	fi
}

REPORT() {
	head_bu "AWS Resources List:"
	for SERVICE in ${SERVICES[*]} ; do 
		FILE=/tmp/$SERVICE
		rm -f $FILE
		head_u "\nChecking $R$SERVICE$N :"
		case $SERVICE in
			EC2)
			if [ -z "$ACTION" ]; then 
				for REGION in ${REGIONS[*]}; do
					Check_EC2 "$REGION"
				done
				PRINT
			else 
				for REGION in ${REGIONS[*]}; do
					Check_EC2 "$REGION"
				done
			fi
			;;
			S3)
				Check_S3 
			;;
			ELASTIC_BEANSTALK) 
			if [ -z "$ACTION" ]; then 
				for REGION in ${REGIONS[*]}; do 
					Check_EB "$REGION"
				done
				PRINT
			else
				for REGION in ${REGIONS[*]}; do 
					Check_EB "$REGION"
				done
			fi
			;;
			RDS)
			if [ -z "$ACTION" ]; then
				for REGION in ${REGIONS[*]}; do 
					Check_RDS "$REGION"
				done
				PRINT
			else
				for REGION in ${REGIONS[*]}; do 
					Check_RDS "$REGION"
				done
			fi
			;;
			CODECOMMIT)
			if [ -z "$ACTION" ]; then
				for REGION in ${REGIONS[*]}; do 
					Check_CC "$REGION"
				done
				PRINT
			else
				for REGION in ${REGIONS[*]}; do 
					Check_CC "$REGION"
				done
			fi
			;;
			CODEBUILD)
			if [ -z "$ACTION" ]; then
				for REGION in ${REGIONS[*]}; do 
					Check_CB "$REGION"
				done
				PRINT
			else
				for REGION in ${REGIONS[*]}; do 
					Check_CC "$REGION"
				done
			fi
			;;
			CODEDEPLOY)
			if [ -z "$ACTION" ]; then
				for REGION in ${REGIONS[*]}; do 
					Check_CD "$REGION"
				done
				PRINT
			else
				for REGION in ${REGIONS[*]}; do 
					Check_CD "$REGION"
				done
			fi
			;;
			CODE_PIPELINE) 
			if [ -z "$ACTION" ]; then
				for REGION in ${REGIONS[*]}; do 
					Check_CP "$REGION"
				done
				PRINT
			else
				for REGION in ${REGIONS[*]}; do 
					Check_CP "$REGION"
				done
			fi
			;;
			CLOUDWATCH)
			if [ -z "$ACTION" ]; then
				for REGION in ${REGIONS[*]}; do 
					Check_CW "$REGION"
				done
				PRINT
			else
				for REGION in ${REGIONS[*]}; do 
					Check_CW "$REGION"
				done
			fi
			;;
			SNS)
			if [ -z "$ACTION" ]; then
				for REGION in ${REGIONS[*]}; do 
					Check_SNS "$REGION"
				done
				PRINT
			else 
				for REGION in ${REGIONS[*]}; do 
					Check_SNS "$REGION"
				done
			fi
			;;
			*) break ;;
		esac
	done
}

REMOVE() {
	ACTION=REMOVE
	REPORT
}

case $1 in 
	report) REPORT ;;
	remove|clean) REMOVE ;;
	*) REPORT ;;
esac
