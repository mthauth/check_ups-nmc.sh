#!/bin/bash

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4


##########################################################################
##########################################################################
##########################################################################

## OID's from http://www.circitor.fr/Mibs/Html/U/UPS-MIB.php

##########################################################################
# The magnitude of the present input frequency.
# UPS-MIB::upsInputFrequency
# value: integer
# method: get
OID_upsInputFrequency="1.3.6.1.2.1.33.1.3.3.1.2"

##########################################################################
# The magnitude of the present input voltage.
# UPS-MIB::upsInputVoltage
# value: integer
# method: get
OID_upsInputVoltage="1.3.6.1.2.1.33.1.3.3.1.3"

##########################################################################
# The present source of output power. The enumeration none(2) indicates 
# that there is no source of output power (and therefore no output power),
# for example, the system has opened the output breaker.
# UPS-MIB::upsOutputSource
# value: enum other(1), none(2), normal(3), bypass(4), battery(5), 
#        booster(6), reducer(7)
OID_upsOutputSource="1.3.6.1.2.1.33.1.4.1"

##########################################################################
# The present output frequency.
# UPS-MIB::upsOutputFrequency
# value: integer
OID_upsOutputFrequency="1.3.6.1.2.1.33.1.4.2"

##########################################################################
# The present output voltage. 
# UPS-MIB::upsOutputVoltage
# value: integer
OID_upsOutputVoltage="1.3.6.1.2.1.33.1.4.4.1.2"


##########################################################################
# The percentage of the UPS power capacity presently being used on this 
# output line, i.e., the greater of the percent load of true power 
# capacity and the percent load of VA.
# UPS-MIB::upsOutputPercentLoad
# value: percent
OID_upsOutputPercentLoad="1.3.6.1.2.1.33.1.4.4.1.5"


##########################################################################
# 
# UPS-MIB::
# value: 
OID_=""


##########################################################################
# 
# UPS-MIB::
# value: 
OID_=""


##########################################################################
# 
# UPS-MIB::
# value: 
OID_=""


##########################################################################
# 
# UPS-MIB::
# value: 
OID_=""



##########################################################################
# The indication of the capacity remaining in the 
# UPS system's batteries. A value of batteryNormal indicates 
# that the remaining run-time is greater than upsConfigLowBattTime. 
# A value of batteryLow indicates that the remaining battery 
# run-time is less than or equal to upsConfigLowBattTime. 
# A value of batteryDepleted indicates that the UPS will be unable 
# to sustain the present load when and if the utility power is lost 
# (including the possibility that the utility power is currently 
# absent and the UPS is unable to sustain the output).
# UPS-MIB::upsBatteryStatus
# values: enum unknown(1), batteryNormal(2), batteryLow(3),
#         batteryDepleted(4)
# method: get
OID_upsBatteryStatus="1.3.6.1.2.1.33.1.2.1"

##########################################################################
# The ambient temperature at or near the UPS Battery casing.
# UPS-MIB::upsBatteryTemperature
# value: integer
# method: get
OID_upsBatteryTemperature="1.3.6.1.2.1.33.1.2.7"

##########################################################################
# An estimate of the battery charge remaining expressed 
# as a percent of full charge.
# UPS-MIB::upsEstimatedChargeRemaining
# values: percent
# method: get
OID_upsEstimatedChargeRemaining="1.3.6.1.2.1.33.1.2.4"

##########################################################################
##########################################################################

##########################################################################
# The present number of active alarm conditions.
# UPS-MIB::upsAlarmsPresent
# values: integer
# method: get
OID_upsAlarmsPresent="1.3.6.1.2.1.33.1.6.1.0"

##########################################################################
# A reference to an alarm description object. 
# The object referenced should not be accessible, 
# but rather be used to provide a unique description 
# of the alarm condition.
# UPS-MIB::upsAlarmDescr
# values: list of OIDs
# method: walk
OID_upsAlarmDescr="1.3.6.1.2.1.33.1.6.2.1.2"





##########################################################################
##########################################################################
##########################################################################
##########################################################################

function get_snmp_value()
{
	host=$1
	oid=$2
	version=${3:-2c}
	community=${4:-public}
	o=$(snmpget -Oqv -v $version -c $community $host $oid)
	echo $o | grep -iq "no such instance" && \
		o=$(snmpgetnext -Oqv -v $version -c $community $host $oid)
	echo $o
	return 0
}

function walk_snmp_values()
{
	host=$1
	oid=$2
	version=${3:-2c}
	community=${4:-public}

	arr=
	snmpwalk -Oqv -v $version -c $community $host $oid | while read l; do
		echo $l;
		arr+=($l); 
	done

	return 0
}

function inputStatus()
{
	echo -n "Input: "
	echo -n $(get_snmp_value $1 $OID_upsInputVoltage)VAC" / "
	echo -n $(($(get_snmp_value $1 $OID_upsInputFrequency)/10))Hz
}

function batteryStatus()
{

	echo -n "Battery: "
	state=$(get_snmp_value $1 $OID_upsBatteryStatus)
	if [ "$state" == "batteryNormal" ] || [ "$state" -eq 2 ]; then
		echo -n "normal"
	elif [ $state == "batteryLow" ] || [ "$state" -eq 3 ]; then
		echo -n "low"
	elif [ $state == "batteryDepleted" ] || [ "$state" -eq 4 ]; then
		echo -n "depleted"
	else
		echo -n $state
	fi
	echo -n " / "$(get_snmp_value $1 $OID_upsEstimatedChargeRemaining)"% / "
	echo -n " "$(get_snmp_value $1 $OID_upsBatteryTemperature)"°C"
}

####################################################################
####################################################################

test $# -eq 0 && \
	echo "no Host or IP address provided" && \
	exit $STATE_UNKNOWN

usv_host="$*"

# count number of current alarms
current_alarms=$(get_snmp_value $usv_host $OID_upsAlarmsPresent)
if [ $current_alarms -eq 0 ]; then
	# if no (0) alarms available, everything is fine
	echo $(inputStatus $usv_host)"," \
		$(batteryStatus $usv_host)
	exit $STATE_OK
else
	# if (>0) alarms available, evaluate them
	walk_snmp_values $usv_host $OID_upsAlarmDescr | while read alarm ; do
		echo "abc" $alarm
	done
	exit $STATE_WARNING
fi


exit $STATE_OK
