<!--- This file is part of Mura CMS.

Mura CMS is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, Version 2 of the License.

Mura CMS is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. �See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Mura CMS. �If not, see <http://www.gnu.org/licenses/>.

Linking Mura CMS statically or dynamically with other modules constitutes
the preparation of a derivative work based on Mura CMS. Thus, the terms and 	
conditions of the GNU General Public License version 2 (�GPL�) cover the entire combined work.

However, as a special exception, the copyright holders of Mura CMS grant you permission
to combine Mura CMS with programs or libraries that are released under the GNU Lesser General Public License version 2.1.

In addition, as a special exception, �the copyright holders of Mura CMS grant you permission
to combine Mura CMS �with independent software modules that communicate with Mura CMS solely
through modules packaged as Mura CMS plugins and deployed through the Mura CMS plugin installation API,
provided that these modules (a) may only modify the �/trunk/www/plugins/ directory through the Mura CMS
plugin installation API, (b) must not alter any default objects in the Mura CMS database
and (c) must not alter any files in the following directories except in cases where the code contains
a separately distributed license.

/trunk/www/admin/
/trunk/www/tasks/
/trunk/www/config/
/trunk/www/requirements/mura/

You may copy and distribute such a combined work under the terms of GPL for Mura CMS, provided that you include
the source code of that other code when and as the GNU GPL requires distribution of source code.

For clarity, if you create a modified version of Mura CMS, you are not obligated to grant this special exception
for your modified version; it is your choice whether to do so, or to make such modified version available under
the GNU General Public License version 2 �without this exception. �You may, if you choose, apply this exception
to your own modified versions of Mura CMS.
--->
<cfcomponent extends="mura.cfobject" output="false">
<cffunction name="init" access="public" returntype="any" output="false">
<cfargument name="configBean" type="any" required="yes"/>
<cfargument name="utility" type="any" required="yes"/>
<cfargument name="mailinglistManager" type="any" required="yes"/>
<cfargument name="settingsManager" type="any" required="yes"/>
<cfargument name="contentRenderer" type="any" required="yes"/>

		<cfset variables.configBean=arguments.configBean />
		<cfset variables.utility=arguments.utility />
		<cfset variables.mailinglistManager=arguments.mailinglistManager />
		<cfset variables.settingsManager=arguments.settingsManager />
		<cfset variables.contentRenderer=arguments.contentRenderer />
		<cfset variables.dsn=variables.configBean.getDatasource()/>
		
<cfreturn this />
</cffunction>

<cffunction name="setMailer" returntype="any" access="public" output="false">
<cfargument name="mailer"  required="true">

	<cfset variables.mailer=arguments.mailer />

</cffunction>

<cffunction name="send" access="public" output="false" returntype="void">
<cfset var clickid=""/>
<cfset var rsEmailList=""/>
<cfset var rsEmail=""/>
<cfset var rsReturnForm=""/>
<cfset var rsForwardForm=""/>
<cfset var rsAddresses=""/>
<cfset var unsubscribe=""/>
<cfset var forward=""/>
<cfset var preBodyHTML=""/>
<cfset var preBodyText=""/>
<cfset var bodyHTML=""/>
<cfset var bodyText=""/>
<cfset var HTMLfieldList=""/>
<cfset var TextfieldList=""/>
<cfset var prevEmail=""/>
<cfset var counter=0/>
<cfset var trackOpen=0/>
<cfset var returnParams=""/>
<cfset var email=""/>
<cfset var f=0/>
<cfset var htmlbodytext=""/>


<!--- <cftransaction> --->
<cfquery name="rsEmailList" datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
Select EmailID from temails where deliverydate <=<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"> and status = 0 and deliverydate is not null and isDeleted = 0
</cfquery>

	<cfloop list="#valuelist(rsemaillist.emailid)#" index="email">
	
	<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
		update temails set status = 99 where emailid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#email#" />
	</cfquery>
	
	<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
		update temails set status = 99 where emailid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#email#" />
	</cfquery>
	
	<cfquery name="rsEmail" datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	select temails.*, tsettings.* from temails inner join tsettings on (temails.siteid=tsettings.siteid) where emailid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#email#" />
	</cfquery>
	
	<cfquery name="rsReturnForm" datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	select filename from tcontent where siteid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#rsEmail.siteID#" /> and active =1 and ((display=1) or (display=2  and tcontent.DisplayStart <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"> AND tcontent.DisplayStop >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">)) 
	and contenthistid in (select contenthistid from tcontentobjects where object='mailing_list_master')	
	</cfquery>
	
	<cfquery name="rsForwardForm" datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	select filename from tcontent where siteid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#rsEmail.siteID#" /> and active =1 and ((display=1) or (display=2  and tcontent.DisplayStart <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"> AND tcontent.DisplayStop >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">)) 
	and contenthistid in (select contenthistid from tcontentobjects where object='forward_email')	
	</cfquery>		
		
		<cfif rsemail.grouplist neq '' and (rsemail.bodyhtml neq '' or rsemail.bodytext neq '')>
			<cfset prevEmail=""/>
			<cfset counter=0/>
			<cfset request.servletEvent = createObject("component","mura.servletEvent").init() />
			<cfset request.servletEvent.setValue("siteID",rsemail.siteID)/>
				
				<!---<cftry>--->
			<cfset rsAddresses=getAddresses(rsEmail.groupList,rsEmail.siteid) />
				
				<!---
				<cfcatch type="database"></cfcatch>
				</cftry>--->
				<cfif rsEmail.format neq "Text">
					<cfif findNoCase("##fname##",rsEmail.bodyhtml)>
					<cfset HTMLfieldList=listAppend(HTMLfieldList,"fname","^") />
					</cfif>
					<cfif findNoCase("##lname##",rsEmail.bodyhtml)>
					<cfset HTMLfieldList=listAppend(HTMLfieldList,"lname","^") />
					</cfif>
					<cfif findNoCase("##company##",rsEmail.bodyhtml)>
					<cfset HTMLfieldList=listAppend(HTMLfieldList,"company","^") />
					</cfif>
				</cfif>
				

				<cfif rsEmail.format neq "HTML">
					<cfif findNoCase("##fname##",rsEmail.bodyText)>
					<cfset TextfieldList=listAppend(TextfieldList,"fname","^") />
					</cfif>
					<cfif findNoCase("##lname##",rsEmail.bodyText)>
					<cfset TextfieldList=listAppend(TextfieldList,"lname","^") />
					</cfif>
					<cfif findNoCase("##company##",rsEmail.bodyText)>
					<cfset TextfieldList=listAppend(TextfieldList,"company","^") />
					</cfif>
				</cfif>
				
				<cfset preBodyHTML = variables.contentRenderer.setDynamicContent(rsemail.bodyhtml)>
				<cfset preBodyText = variables.contentRenderer.setDynamicContent(rsemail.bodytext)>
				
				<cfloop query="rsAddresses">
				
				<cfif REFindNoCase("^[^@%*<>' ]+@[^@%*<>' ]{1,255}\.[^@%*<>' ]{2,5}", trim(rsAddresses.email)) neq 0 
				and prevEmail neq rsAddresses.email>
				<cfset unsubscribe="http://#rsemail.domain##variables.configBean.getServerPort()##variables.configBean.getContext()##variables.contentRenderer.getURLStem(rsemail.siteid,rsreturnform.filename)#?email=#rsaddresses.email#&nocache=1">
				<cfset trackOpen='<img src="http://#variables.settingsManager.getSite(rsEmail.siteid).getDomain("production")##variables.configBean.getServerPort()##variables.configBean.getContext()#/tasks/email/trackOpen.cfm?email=#rsaddresses.email#&emailid=#rsemail.emailid#" style="display:none;">'/>
				<cfset forward="http://#rsemail.domain##variables.configBean.getServerPort()##variables.configBean.getContext()##variables.contentRenderer.getURLStem(rsemail.siteid,rsforwardform.filename)#?emailid=#rsemail.emailid#&from=#rsaddresses.email#&origin=#rsaddresses.email#&nocache=1">
				
				<cfset returnParams = "?doaction=return&emailid=#rsemail.emailid#&email=#rsAddresses.email#&nocache=1">
				<cfset bodyHTML = appendReturnParams(preBodyHTML, returnParams, rsEmail.domain)>
				<cfset bodyText = preBodyText>
				
				<cfif rsEmail.format neq "Text">
					<cfloop list="#HTMLfieldList#" index="f" delimiters="^">	
						<cfset bodyHTML=replace(bodyHTML,"###f###",evaluate("rsAddresses.#f#"),"ALL")>
					</cfloop>
				</cfif>
				
				<cfif rsEmail.format neq "HTML">
					<cfloop list="#TextfieldList#" index="f" delimiters="^">	
						<cfset bodyText=replace(bodyText,"###f###",evaluate("rsAddresses.#f#"),"ALL")>
					</cfloop>
				</cfif>
				
			
				<cftry>
						 <cfswitch expression="#rsemail.format#">
								<cfcase value="HTML">
									<cfsavecontent variable="bodyHTML">
									<cfinclude template="/#variables.configBean.getWebRootMap()#/#rsEmail.siteid#/includes/email/inc_email.cfm">
									</cfsavecontent>
									<cfset variables.mailer.sendHTML(bodyHTML,
															rsAddresses.email,
															rsemail.fromLabel,
															rsemail.subject,
															rsemail.siteid,
															rsemail.replyto,
															"mura_BROADCASTER_START#rsemail.EmailID#mura_BROADCASTER_END"
															) />
								</cfcase>
								<cfcase value="Text">
									<cfset variables.mailer.sendText(bodyText,
															rsAddresses.email,
															rsemail.fromLabel,
															rsemail.subject,
															rsemail.siteid,
															rsemail.replyto,
															"mura_BROADCASTER_START#rsemail.EmailID#mura_BROADCASTER_END"
															) />
								</cfcase>
								<cfcase value="HTML & Text">
									<cfsavecontent variable="bodyHTML">
										<cfinclude template="/#variables.configBean.getWebRootMap()#/#rsEmail.siteid#/includes/email/inc_email.cfm">
									</cfsavecontent>
									<cfset variables.mailer.sendTextAndHTML(bodyText,
															bodyHTML,
															rsAddresses.email,
															rsemail.fromLabel,
															rsemail.subject,
															rsemail.siteid,
															rsemail.replyto,
															"mura_BROADCASTER_START#rsemail.EmailID#mura_BROADCASTER_END"
															) />
								</cfcase>
							</cfswitch> 
							
						    <cfset track(rsemail.emailID, rsAddresses.email, "sent") />
						    <cfset prevEmail=rsAddresses.email />
						    <cfset counter=counter+1 />
					<cfcatch>
						 <cfset variables.utility.logEvent("EmailID:#rsemail.emailid# Subject:#rsemail.subject# Email#rsAddresses.email# was not sent","mura-mail","Error",true) />
						 <cfset track(rsEmail.emailid, rsAddresses.email, "bounce") />
					 </cfcatch>
				  </cftry> 
				</cfif>
				</cfloop>	
					
				<cfif isnumeric(rsemail.numbersent)>
				<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				update temails set status=1, NumberSent=#counter#+numbersent where emailid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#rsEmail.emailID#" />
				</cfquery>
				<cfelse>
				<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				update temails set status=1, NumberSent=#counter# where emailid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#rsEmail.emailID#" />
				</cfquery>
				</cfif>
				
				<cfset variables.utility.logEvent("EmailID:#rsemail.emailid# Subject:#rsemail.subject# was sent","mura-email","Information",true) />
				
			</cfif>
		
		</cfloop>

<!--- </cftransaction> --->

</cffunction>

<cffunction name="forward" access="public" output="false" returntype="void">
<cfargument name="data" type="struct"/>

<cfset var clickid=""/>
<cfset var rsEmailList=""/>
<cfset var rsEmail=""/>
<cfset var rsReturnForm=""/>
<cfset var rsAddressesPre=""/>
<cfset var rsUnsubscribe=""/>
<cfset var rsForwardForm=""/>
<cfset var rsAddresses=""/>
<cfset var unsubscribe=""/>
<cfset var forward=""/>
<cfset var preBodyHTML=""/>
<cfset var preBodyText=""/>
<cfset var bodyHTML=""/>
<cfset var bodyText=""/>
<cfset var HTMLfieldList=""/>
<cfset var TextfieldList=""/>
<cfset var member=""/>
<cfset var memberBean=""/>
<cfset var trackOpen=""/>
<cfset var returnParams=""/>
<cfset var t=0/>
<cfset var f=0/>


<cfset member=structNew()/>
<cfset member.email=arguments.data.origin>
<cfset member.siteid=arguments.data.siteid>
<cfset memberBean=variables.mailingListManager.readMember(member)/>

	<cfquery name="rsEmail" datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	select temails.*, tsettings.* from temails inner join tsettings on (temails.siteid=tsettings.siteid) where emailid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.data.emailID#" />
	</cfquery>

	<cfquery name="rsReturnForm" datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	select filename from tcontent where siteid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#rsEmail.siteID#" /> and active =1 and ((display=1) or (display=2  and tcontent.DisplayStart <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"> AND tcontent.DisplayStop >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">)) 
	and contenthistid in (select contenthistid from tcontentobjects where object='mailing_list_master')	
	</cfquery>
	
	<cfquery name="rsForwardForm" datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	select filename from tcontent where siteid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#rsEmail.siteID#" /> and active =1 and ((display=1) or (display=2  and tcontent.DisplayStart <= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#"> AND tcontent.DisplayStop >= <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">)) 
	and contenthistid in (select contenthistid from tcontentobjects where object='forward_email')	
	</cfquery>
	
				<cfset request.servletEvent = createObject("component","mura.servletEvent").init() />
				<cfset request.servletEvent.setValue("siteID",rsemail.siteID)/>
				
				<cfif rsEmail.format neq "Text">
					<cfif findNoCase("##fname##",rsEmail.bodyhtml)>
					<cfset HTMLfieldList=listAppend(HTMLfieldList,"fname","^") />
					</cfif>
					<cfif findNoCase("##lname##",rsEmail.bodyhtml)>
					<cfset HTMLfieldList=listAppend(HTMLfieldList,"lname","^") />
					</cfif>
					<cfif findNoCase("##company##",rsEmail.bodyhtml)>
					<cfset HTMLfieldList=listAppend(HTMLfieldList,"company","^") />
					</cfif>
				</cfif>
				

				<cfif rsEmail.format neq "HTML">
					<cfif findNoCase("##fname##",rsEmail.bodyText)>
					<cfset TextfieldList=listAppend(TextfieldList,"fname","^") />
					</cfif>
					<cfif findNoCase("##lname##",rsEmail.bodyText)>
					<cfset TextfieldList=listAppend(TextfieldList,"lname","^") />
					</cfif>
					<cfif findNoCase("##company##",rsEmail.bodyText)>
					<cfset TextfieldList=listAppend(TextfieldList,"company","^") />
					</cfif>
				</cfif>

				<cfset preBodyHTML = variables.contentRenderer.setDynamicContent(rsemail.bodyhtml)>
				<cfset preBodyText = variables.contentRenderer.setDynamicContent(rsemail.bodyText)>
				
				<cfloop list="#arguments.data.to#" index="t">
				
				<cfif REFindNoCase("^[^@%*<>' ]+@[^@%*<>' ]{1,255}\.[^@%*<>' ]{2,5}", trim(t)) neq 0>
				<cfset unsubscribe="http://#rsemail.domain##variables.configBean.getServerPort()##variables.configBean.getContext()##variables.contentRenderer.getURLStem(rsemail.siteid,rsreturnform.filename)#?email=#t#&nocache=1">
				<cfset forward="http://#rsemail.domain##variables.configBean.getServerPort()##variables.configBean.getContext()##variables.contentRenderer.getURLStem(rsemail.siteid,rsforwardform.filename)#?emailid=#rsemail.emailid#&from=#t#&origin=#arguments.data.origin#&nocache=1">
				<cfset trackOpen='<img src="http://#variables.settingsManager.getSite(rsEmail.siteid).getDomain("production")##variables.configBean.getServerPort()##variables.configBean.getContext()#/tasks/email/trackOpen.cfm?email=#t#&emailid=#rsemail.emailid#" style="display:none;">'/>

				<cfset returnParams = "?doaction=return&emailid=#rsemail.emailid#&email=#t#&nocache=1">
				<cfset bodyHTML = appendReturnParams(preBodyHTML, returnParams, rsEmail.domain)>		
				<cfset bodyText = preBodyText>
				
				<cfif rsEmail.format neq "Text">
					<cfloop list="#HTMLfieldList#" index="f" delimiters="^">	
						<cfset bodyHTML=replace(bodyHTML,"###f###",evaluate("memberBean.get#f#()"),"ALL")>
					</cfloop>
				</cfif>
				
					<cftry>
						 <cfswitch expression="#rsemail.format#">
								<cfcase value="HTML">
									<cfsavecontent variable="bodyHTML">
									<cfinclude template="/#variables.configBean.getWebRootMap()#/#rsEmail.siteid#/includes/email/inc_email.cfm">
									</cfsavecontent>
									<cfset variables.mailer.sendHTML(bodyHTML,
															t,
															rsemail.fromLabel,
															"#arguments.data.from# has forwarded you this email from #rsemail.site#",
															rsemail.siteid,
															arguments.data.from
															) />
								</cfcase>
								<cfcase value="Text">
									<cfset variables.mailer.sendText(bodyText,
															t,
															rsemail.fromLabel,
															"#arguments.data.from# has forwarded you this email from #rsemail.site#",
															rsemail.siteid,
															arguments.data.from
															) />
								</cfcase>
								<cfcase value="HTML & Text">
									<cfsavecontent variable="bodyHTML">
										<cfinclude template="/#variables.configBean.getWebRootMap()#/#rsEmail.siteid#/includes/email/inc_email.cfm">
									</cfsavecontent>
									<cfset variables.mailer.sendTextAndHTML(bodyText,
															bodyHTML,
															t,
															rsemail.fromLabel,
															"#arguments.data.from# has forwarded you this email from #rsemail.site#",
															rsemail.siteid,
															arguments.data.from
															) />
								</cfcase>
							</cfswitch> 
						<cfcatch>
							<cfset variables.utility.logEvent("#rsemail.subject#^#t#","mura-mail","Error",true) />
						</cfcatch>
					</cftry>
				</cfif>
		</cfloop>
					
				<cfif isnumeric(rsemail.numbersent) and listlen(arguments.data.to) gt 0>
				<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				update temails set status=1, NumberSent=#listlen(arguments.data.to)#+numbersent where emailid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#rsEmail.emailID#" />
				</cfquery>
				<cfelse>
				<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				update temails set status=1, NumberSent=#listlen(arguments.data.to)# where emailid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#rsEmail.emailID#" />
				</cfquery>
				</cfif>
				

</cffunction>

<cffunction name="track" output="false" returntype="void">
	<cfargument name="emailid" type="string" required="yes">
	<cfargument name="email" type="string" required="yes">
	<cfargument name="type" type="string" required="yes">
	<cfset var rs=""/>
	<cfset var returnURL=""/>
		
	<!--- add a flag for the corresponding action: return, bounce, open --->
	<cfif arguments.type eq "returnClick" or arguments.type eq "bounce" or arguments.type eq "emailOpen">
		<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			update temailstats 
			set #arguments.type# = 1
			where emailid = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.emailID#" />
			and email = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.email#" />
		</cfquery>
	</cfif>

	<cfif arguments.type eq "returnClick">
		<cfif isDefined('url.path')>
			<cfset returnUrl = "http://#listFirst(cgi.http_host,":")##url.path#">
		<cfelse>
			<cfset returnUrl = "http://#listFirst(cgi.http_host,":")##cgi.script_name#">
		</cfif>
		<!--- track what link was clicked --->
		<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			insert into temailreturnstats 
			(emailid, email, url, created) 
			VALUES
			(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.emailID#" />, <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.email#" />, <cfqueryparam cfsqltype="cf_sql_varchar" value="#returnURL#" />, <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">)
		</cfquery>
	</cfif>
	
	<cfif arguments.type eq "sent">
		<!--- track a sent email --->
		<cfquery datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			Insert Into temailstats (emailid,email,created,#arguments.type#)
			values(<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.emailID#" />,<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.email#" />,<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">,1)
		</cfquery>
	</cfif>		
</cffunction>

<cffunction name="trackBounces" output="false" returntype="void">
	<cfargument name="siteid" type="string" required="yes">
	<cfset var startPos = "" />
	<cfset var endPos = "" />
	<cfset var emailID = "" />
	<cfset var email = "" />
	<cfset var returnVar = "" />
	<cfset var newLine = "" />
	<cfset var messageList = "" />
	<cfset var getEmail = "">
	<cfset var mailserverip=variables.settingsManager.getSite(arguments.siteid).getMailServerIP() />
	<cfset var mailserverusername=variables.settingsManager.getSite(arguments.siteid).getMailServerUsername() />
	<cfset var mailserverpassword=variables.settingsManager.getSite(arguments.siteid).getMailServerPassword() />
	<cfset var mailserverpopport=variables.settingsManager.getSite(arguments.siteid).getMailServerPOPPort() />
	<cfset var ssl=variables.settingsManager.getSite(arguments.siteid).getMailServerSSL() />
	<cfset var javaSystem="" />
	<cfset var javaSystemProps="" />
	
	<cfif listFirst(mailserverip,".") eq "smtp">
		<cfset mailserverip="pop." & listRest(mailserverip,".") />
	</cfif>
	
	<cfif len(mailserverip) and len(mailserverusername) and len(mailserverpassword)>
	<cftry>
	<cfif ssl>
		<cfset javaSystem = createObject("java", "java.lang.System") />
		<cfset javaSystemProps = javaSystem.getProperties() />
		<cfset javaSystemProps.setProperty("mail.pop3.socketFactory.class", "javax.net.ssl.SSLSocketFactory") />
	</cfif>
	<cfpop
	server="#mailserverip#" 
	username="#mailserverusername#" 
	password="#mailserverpassword#"
	action="getAll"
	port="#mailserverpopport#"
	name="getEmail">
	<cfif ssl>
		<cfset javaSystemProps.setProperty("mail.pop3.socketFactory.class", "javax.net.SocketFactory") />  
	</cfif>
	<cfset newLine = Chr(13) & Chr(10)>
	
	<cfloop query = "getEmail">	
		<cfset startPos = findNoCase("mura_broadcaster_start", body)>
		<cfset endPos = findNoCase("mura_broadcaster_end", body)>
		<cfif startPos gt 0 and endPos gt 0>
			<cfset messageList = listAppend(messageList, UID) />
			<cfset startPos = startPos + 22>
			<cfset emailID = mid(body, startPos, endPos - startPos)>
			<cfset emailID = trim(emailID)>

			<!--- now get the "to" email" --->			
			<cfset startPos = findNoCase("failed recipient:", body)>
			<cfset endPos = findNoCase(newLine, body, startPos)>
			<cfif startPos gt 0 and endPos gt 0>
				<cfset startPos = startPos + 17>
				<cfset email = mid(body, startPos, endPos - startPos)>
				<cfset email = trim(email)>
				
				<!--- now track the bounce --->
				<cfset track(emailID, email, "bounce") />				
			</cfif>
		</cfif>
	</cfloop>
	
	<!--- get all message UIDs 
	<cfset messageList = ValueList(getEmail.uid, ",")>
	--->
	
	<!--- delete all the messages that have been processed --->
	<cfif ssl>
		<cfset javaSystemProps.setProperty("mail.pop3.socketFactory.class", "javax.net.ssl.SSLSocketFactory") />
	</cfif>
	<cfpop
	server="#mailserverip#" 
	username="#mailserverusername#" 
	password="#mailserverpassword#"
	action="delete"
	uid="#messageList#">
	<cfif ssl>
		<cfset javaSystemProps.setProperty("mail.pop3.socketFactory.class", "javax.net.SocketFactory") />  
	</cfif>
	<cfcatch>
		<cfif ssl>
			<cfset javaSystemProps.setProperty("mail.pop3.socketFactory.class", "javax.net.SocketFactory") />  
		</cfif>
	</cfcatch>
	</cftry>
	</cfif>
	
</cffunction>

<cffunction name="getAddresses" returntype="query" access="public">
<cfargument name="groupList" type="String" required="true">
<cfargument name="siteID" type="String" required="true">

<cfset var rsAddressesPre=""/>
<cfset var rsAddresses=""/>
<cfset var rsUnsubscribe = ""/>
<cfset var G=0/>
<cfset var f=0/>


<cfquery name="rsAddressesPre" datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				
				SELECT DISTINCT tusers.Email, tusers.fname, tusers.lname, tusers.company
				FROM         tusersmemb INNER JOIN
							 tusers ON tusersmemb.UserID = tusers.UserID
				WHERE     
				<cfif Len(arguments.grouplist)>  
					tusersmemb.GroupID IN (
					<cfloop from="1" to="#listlen(arguments.GroupList)#" index="G"><cfqueryparam cfsqltype="cf_sql_varchar" value="#listgetat(arguments.GroupList,G)#" /> <cfif G lt listlen(arguments.GroupList)>,</cfif></cfloop>
					)
				<cfelse>
					0=1  
				</cfif>
				
				AND tusers.InActive = 0 AND tusers.subscribe = 1 
				
				
				<cfif len(arguments.grouplist)>
				Union
				
				SELECT DISTINCT tusers.Email, tusers.fname, tusers.lname, tusers.company
				FROM         tusersinterests INNER JOIN
							 tusers ON tusersinterests.UserID = tusers.UserID
							 INNER JOIN tcontentcategories ON (tusersinterests.categoryID=tcontentcategories.categoryID)
				WHERE
				<cfif Len(arguments.grouplist)>       
					(
					<cfloop from=1 to="#listLen(arguments.grouplist)#" index="f">
							tcontentcategories.Path like <cfqueryparam cfsqltype="cf_sql_varchar" value="%#listGetAt(arguments.grouplist,f)#%" />
							<cfif f lt listLen(arguments.grouplist) > or </cfif>
					</cfloop>
					) 
				<cfelse>
					0=1  
				</cfif>
				AND tusers.InActive = 0 AND tusers.subscribe = 1
				</cfif> 
					
				Union
				
				SELECT DISTINCT tmailinglistmembers.Email, tmailinglistmembers.fname, tmailinglistmembers.lname, tmailinglistmembers.company
				FROM         tmailinglistmembers   INNER JOIN tmailinglist ON(tmailinglistmembers.mlid=tmailinglist.mlid)               
				WHERE     
				<cfif Len(arguments.grouplist)>     
					tmailinglistmembers.mlid IN (
					<cfloop from="1" to="#listlen(arguments.GroupList)#" index="G"><cfqueryparam cfsqltype="cf_sql_varchar" value="#listgetat(arguments.GroupList,G)#" /> <cfif G lt listlen(arguments.GroupList)>,</cfif></cfloop>) 
				<cfelse>
					0=1  
				</cfif>
				AND tmailinglist.siteid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#" /> 
				and tmailinglistmembers.isVerified = 1
				</cfquery>
				
				<cfquery name="rsUnsubscribe" datasource="#variables.dsn#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				select tmailinglistmembers.email from tmailinglistmembers INNER JOIN tmailinglist ON (tmailinglistmembers.mlid=tmailinglist.mlid)
				WHERE tmailinglist.ispurge=1 and  tmailinglist.siteid= <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.siteID#" />
				
				union 
				
				select email from tusers where 
					(
					siteid='#variables.settingsManager.getSite(arguments.siteID).getPublicUserPoolID()#'
					or siteid='#variables.settingsManager.getSite(arguments.siteID).getPrivateUserPoolID()#'
					)
				and subscribe=0
				</cfquery>
				
				
				<cfquery name="rsAddresses" dbtype="query">
				select distinct email, fname, lname, company from rsAddressesPre 
				<cfif rsUnsubscribe.recordcount>
				where email not in (''<cfloop query="rsUnsubscribe">,<cfqueryparam cfsqltype="cf_sql_varchar" value="#rsUnsubscribe.email#" /></cfloop>)
				</cfif>
				</cfquery>
				
				<cfreturn rsAddresses>
</cffunction>

<cffunction name="appendReturnParams" access="private" returntype="string">
		<cfargument name="_text" default="" required="yes">
		<cfargument name="_returnParams" default="" required="yes">
		<cfargument name="_domain" default="" required="yes">
		
		<cfset var reg = "<a [^>]*href=""([^""]+)""[^>]*>">
		<cfset var res = "">
		<cfset var startPos = 1>
		<cfset var returnParams = "">
		<cfset var loop = true>
		<cfset var link = "">
		<cfset var text=""/>
		<cfset var domain = "">
		
		<cfset text = arguments._text>
		<cfset returnParams = arguments._returnParams>
		<cfset domain = arguments._domain>
		
		<cfloop condition="#loop#">
			<cfset res = REFindNoCase(reg,text,startPos,true)>
			<cfif res.pos[1] is 0>
				<!--- no link ---> 
				<cfset loop = false>
			<cfelse>
				<!--- search link and saves match on temp variables --->
				<cfset startPos = res.pos[1] + res.len[1]>
				<cfset link = mid(text,res.pos[2],res.len[2])>
			</cfif>
			<cfif loop>
				<cfif link contains domain>
					<!--- add return params to link --->
					<cfif find("?", link) gt 0>
						<cfset link = replace(link, "?", returnParams & "&")>
						<cfset startPos = startPos + len(returnParams) + 1>
					<cfelse>
						<cfset link = link & returnParams>
						<cfset startPos = startPos + len(returnParams)>
					</cfif>
					<cfset text = mid(text,1,res.pos[2]-1) & link & mid(text,res.pos[2]+res.len[2], len(text)-(res.pos[2]+res.len[2]+1))>
				</cfif>
			</cfif>
		</cfloop>
		
		<cfreturn text>
	</cffunction>

</cfcomponent>