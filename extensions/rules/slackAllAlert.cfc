<cfcomponent extends="bugLog.components.baseRule" 
            displayName="Slack Alert"
            hint="Sends an alert via Slack Webhooks on the first occurrence of an message with the given conditions">

    <cfproperty name="webhookURL" type="string" displayName="WebhookURL" hint="Webhook URL">
    <cfproperty name="application" type="string" buglogType="application" displayName="Application" hint="The application name that will trigger the rule. Leave empty to look for all applications">
    <cfproperty name="host" type="string" buglogType="host" displayName="Host Name" hint="The host name that will trigger the rule. Leave empty to look for all hosts">
    <cfproperty name="severity" type="string" buglogType="severity" displayName="Severity Code" hint="The severity that will trigger the rule. Leave empty to look for all severities">

    <cfset variables.ID_NOT_SET = -9999999 />
    <cfset variables.ID_NOT_FOUND = -9999990 />

    <cffunction name="init" access="public" returntype="bugLog.components.baseRule">
        <cfargument name="webhookURL" type="string" required="true">
        <cfargument name="application" type="string" required="false" default="">
        <cfargument name="host" type="string" required="false" default="">
        <cfargument name="severity" type="string" required="false" default="">
        <cfset variables.config.webhookURL = arguments.webhookURL>
        <cfset variables.config.application = arguments.application>
        <cfset variables.config.host = arguments.host>
        <cfset variables.config.severity = arguments.severity>
        <cfset variables.applicationID = variables.ID_NOT_SET>
        <cfset variables.hostID = variables.ID_NOT_SET>
        <cfset variables.severityID = variables.ID_NOT_SET>
        <cfset variables.lastEmailTimestamp = createDateTime(1800,1,1,0,0,0)>
        <cfreturn this>
    </cffunction>

    <cffunction name="processRule" access="public" returnType="boolean"
                hint="This method performs the actual evaluation of the rule. Each rule is evaluated on a rawEntryBean. 
                        The method returns a boolean value that can be used by the caller to determine if additional rules
                        need to be evaluated.">
        <cfargument name="rawEntry" type="bugLog.components.rawEntryBean" required="true">
        <cfargument name="entry" type="bugLog.components.entry" required="true">

        <cfscript>
            logTrigger(entry);
            boop(entry, rawEntry);
        </cfscript>

        <!--- this method must be implemented by rules that extend the base rule --->
        <cfreturn true>
    </cffunction>

    <cffunction name="boop" access="private" returntype="void" output="true">
        <cfargument name="entry" type="bugLog.components.entry" required="true">
        <cfargument name="rawEntry" type="bugLog.components.rawEntryBean" required="true">
       
        <cfscript>
            var payload = {
                "username" = "BugLogHQ",
                "icon_url" = getBaseBugLogHREF() & "hq/images/bug.png",
                "text" = "*[#rawEntry.getHostName()#][#rawEntry.getSeverityCode()#] #rawEntry.getMessage()#*" & chr(10)
                        & "Application: `#rawEntry.getApplicationCode()#`" & chr(10)
                        & "<" & getBugEntryHREF(entry.getEntryID()) & ">"
            };
        </cfscript>

        <cfhttp method="post" url="#variables.config.webhookURL#">
            <cfhttpparam type="header" name="Content-Type" value="application/json">
            <cfhttpparam type="body" value="#serializeJson(payload)#">
        </cfhttp>

        <cfset writeToCFLog("'SlackAlert' rule fired. Alert sent. Msg: '#rawEntry.getMessage()#'")>
    </cffunction>

    <cffunction name="explain" access="public" returntype="string">
        <cfset var rtn = "Sends an alert to Slack via Webhooks for every bug received">
        <cfif variables.config.application  neq "">
            <cfset rtn &= " from application <b>#variables.config.application#</b>">
        </cfif>
        <cfif variables.config.severity  neq "">
            <cfset rtn &= " with a severity of <b>#variables.config.severity#</b>">
        </cfif>
        <cfif variables.config.host  neq "">
            <cfset rtn &= " from host <b>#variables.config.host#</b>">
        </cfif>
        <cfreturn rtn>
    </cffunction>

</cfcomponent>