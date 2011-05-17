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

<cffunction name="init" returntype="any" access="public" output="false">
	<cfargument name="configBean" type="any" required="yes"/>
	<cfargument name="utility" type="any" required="yes"/>
	<cfargument name="settingsManager" type="any" required="yes"/>
	<cfargument name="userDAO" type="any" required="yes"/>
	<cfargument name="pluginManager" type="any" required="yes"/>
		<cfset variables.configBean=arguments.configBean />
		<cfset variables.globalUtility=arguments.utility />
		<cfset variables.settingsManager=arguments.settingsManager />
		<cfset variables.userDAO=arguments.userDAO />
		<cfset variables.pluginManager=arguments.pluginManager />
	<cfreturn this />
</cffunction>

<cffunction name="setMailer" returntype="any" access="public" output="false">
<cfargument name="mailer"  required="true">

	<cfset variables.mailer=arguments.mailer />

</cffunction>

<cffunction name="getUserData" returntype="query" access="public">
	<cfargument name="userid" type="string" default="#session.mura.userID#">
	<cfset var rsuser=""/>
	<cfquery name="rsuser" datasource="#variables.configBean.getDatasource()#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	select * from tusers where userid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#">
	</cfquery>
	<cfreturn rsuser>
</cffunction>

<cffunction name="login" returntype="boolean">
		<cfargument name="username" type="string" required="true" default="">
		<cfargument name="password" type="string" required="true" default="">
		<cfargument name="siteid" type="string" required="false" default="">
		<cfset var rolelist = "" />
		<cfset var rsUser = "" />
		<cfset var user = "" />
		<cfset var group = "" />
		<cfset var lastLogin = now() />
		<cfset var pluginEvent = createObject("component","mura.event").init(arguments) />
		<cfset var strikes = createObject("component","mura.user.userstrikes").init(arguments.username,variables.configBean) />
		
		<cfif yesNoFormat(variables.configBean.getValue("useLegacySessions"))>
			<cflogout>
		</cfif>
		
		<cfparam name="session.blockLoginUntil" type="string" default="#strikes.blockedUntil()#" />
		
		<cfif len(arguments.siteID)>
			<cfset variables.pluginManager.announceEvent('onSiteLogin',pluginEvent)/>
		<cfelse>
			<cfset variables.pluginManager.announceEvent('onGlobalLogin',pluginEvent)/>
		</cfif>
		
		<cfquery datasource="#application.configBean.getDatasource()#" name="rsUser" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
		SELECT * FROM tusers WHERE
		username=<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.username)#"> 
		AND 
		(
			password=<cfqueryparam cfsqltype="cf_sql_varchar" value="#hash(trim(arguments.password))#">
			<cfif not variables.configBean.getEncryptPasswords() and len(trim(arguments.password)) neq 32>
			OR
			password=<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.password)#">
			</cfif>
		)
		AND Type = 2 
		and inactive=0
		</cfquery>
		
		<!---
		(not isDate(session.blockLoginUntil) 
			or (isDate(session.blockLoginUntil) and session.blockLoginUntil lt now()))
		--->
		<cfif rsUser.RecordCount GREATER THAN 0
			and not strikes.isBlocked()>
			
				<cfif rsUser.isPublic and (arguments.siteid eq '' or variables.settingsManager.getSite(arguments.siteid).getPublicUserPoolID() neq rsUser.siteid)>
					
					<cfset strikes.addStrike()>
										
					<cfreturn false  >
				</cfif>				
					
				<cfset session.blockLoginUntil=""/>
				
				<cfset loginByQuery(rsUser)/>
				<cfset strikes.clear()>
				<cfif len(arguments.siteID)>
					<cfset variables.pluginManager.announceEvent('onSiteLoginSuccess',pluginEvent)/>
				<cfelse>
					<cfset variables.pluginManager.announceEvent('onGlobalLoginSuccess',pluginEvent)/>
				</cfif>
					
				<cfreturn true />
		
		<cfelse>
			<cfif not strikes.isBlocked()>
				<cfset strikes.addStrike()>
			<cfelse>
			
				<cfif len(arguments.siteID)>
					<cfset variables.pluginManager.announceEvent('onSiteLoginBlocked',pluginEvent)/>
				<cfelse>
					<cfset variables.pluginManager.announceEvent('onGlobalLoginBlocked',pluginEvent)/>
				</cfif>
				
				<cfset session.blockLoginUntil=strikes.blockedUntil()/>
		
			</cfif>	
		</cfif>
						
		<cfreturn false />
</cffunction>
	
<cffunction name="loginByUserID" returntype="boolean">
		<cfargument name="userid" type="string" required="true" default="">
		<cfargument name="siteid" type="string" required="false" default="">
		<cfset var rolelist = "" />
		<cfset var rsUser = "" />
		<cfset var user = "" />
		<cfset var group = "" />
		<cfset var lastLogin = now() />
		<cfset var pluginEvent = createObject("component","mura.event").init(arguments) />
		
		<cflogout>
		<cfquery datasource="#variables.configBean.getDatasource()#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#" name="rsUser">
		SELECT * FROM tusers WHERE userid=<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.userID#"> AND Type = 2
		and inactive=0
		</cfquery>
		
		
			<cfif rsUser.RecordCount GREATER THAN 0>
			
				<cfif rsUser.isPublic and variables.settingsManager.getSite(arguments.siteid).getPublicUserPoolID() neq rsUser.siteid>
					<cfreturn false  >
				</cfif>				
				
				
				<cfset loginByQuery(rsUser)/>
				
				<cfset pluginEvent.setValue("username",rsUser.username)>
				<cfset pluginEvent.setValue("password",rsUser.password)>
				<cfset pluginEvent.setValue("siteid",rsUser.siteid)>
				<cfset pluginEvent.setValue("remoteID",rsUser.remoteID)>
				<cfset pluginEvent.setValue("userID",arguments.userID)>
				
				<cfif len(arguments.siteID)>
					<cfset variables.pluginManager.announceEvent('onSiteLoginSuccess',pluginEvent)/>
				<cfelse>
					<cfset variables.pluginManager.announceEvent('onGlobalLoginSuccess',pluginEvent)/>
				</cfif>
				
				<cfreturn true />
		</cfif>
				
		<cfreturn false />
	</cffunction>

<cffunction name="loginByQuery">
<cfargument name="rsUser"/>
		<cfset var rolelist = "" />
		<cfset var group = "" />
		<cfset var lastLogin = now() />
		<cfset var rsGetRoles = "" />
		<cfset var user=""/>

				<cfquery name="RsGetRoles" datasource="#variables.configBean.getDatasource()#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				Select groupname, isPublic, siteid from tusers where userid in
				(Select GroupID from tusersmemb where userid='#rsuser.userid#')
				</cfquery>
				
				<cfloop query="rsGetRoles">
					<cfset rolelist=listappend(rolelist, "#rsGetRoles.groupname#;#rsGetRoles.siteid#;#rsGetRoles.isPublic#")>
				</cfloop>
							
				<cfif not rsUser.isPublic>
					<cfset rolelist=listappend(rolelist, 'S2IsPrivate;#rsuser.siteid#')>
					<cfset rolelist=listappend(rolelist, 'S2IsPrivate')>
				<cfelse>
					<cfset rolelist=listappend(rolelist, 'S2IsPublic;#rsuser.siteid#')>
					<cfset rolelist=listappend(rolelist, 'S2IsPublic')>
				</cfif>
					
				<cfif rsuser.s2>
					<cfset rolelist=listappend(rolelist, 'S2')>
				</cfif>
				
				<cfif yesNoFormat(variables.configBean.getValue("useLegacySessions"))>
					<cfif isDate(rsuser.lastLogin)>
						<cfset lastLogin=rsuser.lastLogin/>
					</cfif>
					
					<cfif rsuser.company neq ''>
						<cfset group=rsuser.company>
					<cfelse>
						<cfset group="#rsUser.Fname# #rsUser.Lname#">
					</cfif>
					
					<cfif rsuser.lname eq '' and rsuser.fname eq ''>
						<cfset user=rsuser.company>
					<cfelse>
						<cfset user="#rsUser.Fname# #rsUser.Lname#">
					</cfif>
					
					<cflogin>
					<cfloginuser name="#rsuser.userID#^#user#^#dateFormat(lastLogin,'m/d/yy')#^#group#^#rsUser.username#^#dateFormat(rsUser.passwordCreated,'m/d/yy')#^#rsUser.password#"
					 roles="#rolelist#"
					 password="#rsUser.password#">
					</cflogin>	
				</cfif>
				
				<cfquery datasource="#variables.configBean.getDatasource()#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
				UPDATE tusers SET LastLogin = <cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
				WHERE tusers.UserID='#rsUser.UserID#'
				</cfquery>
				
				<cfset setUserStruct(rsuser,rolelist)>
				
				<cfset variables.globalUtility.logEvent("UserID:#rsuser.userid# Name:#rsuser.fname# #rsuser.lname# logged in at #now()#","mura-users","Information",true) />


</cffunction>

<cffunction name="getUserByEmail" returntype="query" output="false">
	<cfargument name="email" type="string">
	<cfargument name="siteid" type="string" required="yes" default="">
	<cfset var rsCheck=""/>
	
		<cfquery name="rsCheck" datasource="#variables.configBean.getDatasource()#" username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
		select * from tusers where type=2 and inactive=0 and email=<cfqueryparam cfsqltype="cf_sql_varchar" value="#trim(arguments.email)#">
		<cfif arguments.siteid neq ''>
		and (
		(siteid='#variables.settingsManager.getSite(arguments.siteid).getPrivateUserPoolID()#' and isPublic=0)
		or
		(siteid='#variables.settingsManager.getSite(arguments.siteid).getPublicUserPoolID()#' and isPublic=1)
		)
		<cfelse>
		and isPublic=0
		</cfif>
		</cfquery>
		
	<cfreturn rsCheck>
	</cffunction>

<cffunction name="sendLoginByEmail" output="false" returntype="string"  access="public">
	<cfargument name="email" type="string">
	<cfargument name="siteid" type="string" required="yes" default="">
	<cfargument name="returnURL" type="string" required="yes" default="#listFirst(cgi.http_host,":")##cgi.SCRIPT_NAME#">
	<cfset var msg="No account currently exists with the email address '#arguments.email#'.">
	<cfset var struser=structnew()>
	<cfset var rsuser = ""/>
	<cfset var userBean = ""/>
	<cfset var autoresetpasswords=variables.configBean.getValue("autoresetpasswords")>
	
		<cfif REFindNoCase("^[^@%*<>' ]+@[^@%*<>' ]{1,255}\.[^@%*<>' ]{2,5}", trim(arguments.email)) neq 0>
					<cfset rsuser=getUserByEmail('#arguments.email#','#arguments.siteid#')>
				
					<cfif rsuser.recordcount>
						<cfloop query="rsuser">
						<cfset userBean=variables.userDAO.read(rsuser.userid)>

							<cfif userBean.getUsername() neq ''>
								<cfif autoresetpasswords>
									<cfset userBean.setPassword(getRandomPassword()) />
									<cfset userBean.save() />
								</cfif>
						
								<cfset struser=userBean.getAllValues()>
								<cfset struser.fieldnames='Username,Password'>
								<cfif arguments.siteid eq ''>
									<cfset struser.from= variables.configBean.getTitle()/>
								<cfelse>
									<cfset struser.from=variables.settingsManager.getSite(arguments.siteid).getSite()>
								</cfif>
								
								<cfset sendLogin(struser,'#arguments.email#','#struser.from#','#struser.from# Account Information','#arguments.siteid#','','')>
								<cfset msg="Your account information has been sent to you.">
							</cfif>
						</cfloop>
					</cfif>
		<cfelse>
					<cfset  msg="The email address '#arguments.email#' is not a valid format.">
		</cfif>
	<cfreturn msg>
	</cffunction>
	
<cffunction name="sendLoginByUser" output="false" returntype="boolean"  access="public">
	<cfargument name="userBean" type="any">
	<cfargument name="siteid" type="string" required="yes" default="" >
	<cfargument name="returnURL" type="string" required="yes" default="#listFirst(cgi.http_host,":")##cgi.SCRIPT_NAME#">
	<cfargument name="isPublicReg" required="yes" type="boolean" default="false"/>
	
	<cfset var struser=structnew()>
	<cfset var bcc="">
	<cfset var autoresetpasswords=variables.configBean.getValue("autoresetpasswords")>
	
		<cfif autoresetpasswords>
			<cfset arguments.userBean.setPassword(getRandomPassword()) />
			<cfset arguments.userBean.save() />
		</cfif>
		<cfset struser=arguments.userBean.getAllValues()>
		
		<cfset struser.fieldnames='Username,Password'>
		<cfif arguments.siteid eq ''>
			<cfset struser.from= variables.configBean.getTitle()/>
		<cfelse>
			<cfset struser.from=variables.settingsManager.getSite(arguments.siteid).getSite()>
		</cfif>
	
		<cfif arguments.isPublicReg and variables.settingsManager.getSite(arguments.siteid).getExtranetPublicRegNotify() neq ''>
			<cfset bcc=variables.settingsManager.getSite(arguments.siteid).getExtranetPublicRegNotify()>
		</cfif>
								
		<cfset sendLogin(struser,'#arguments.userBean.getEmail()#','#struser.from#','#struser.from# Account Information','#arguments.siteid#','',bcc)>
	
	<cfreturn true/>
</cffunction>

<cffunction name="sendLogin" returntype="void" output="false">
<cfargument name="args" type="struct" default="#structnew()#">
<cfargument name="sendto" type="string" default="">
<cfargument name="from" type="string" default="">
<cfargument name="subject" type="string" default="">
<cfargument name="siteid" type="string" default="">
<cfargument name="reply" required="yes" type="string" default="">
<cfargument name="bcc"  required="yes" type="string" default="">

<cfset var sendLoginScript=""/>
<cfset var mailText=""/>
<cfset var username=arguments.args.username/>
<cfset var password=arguments.args.password/>
<cfset var firstname=arguments.args.fname/>
<cfset var lastname=arguments.args.lname/>
<cfset var contactEmail=""/>
<cfset var contactName=""/>
<cfset var finder=""/>
<cfset var theString=""/>
<cfset var autoresetpasswords=variables.configBean.getValue("autoresetpasswords")>
<cfset var returnID=createUUID()>
<cfset var editProfileURL="">
<cfset var returnURL="">		
<cfset var urlBase="http://#listFirst(cgi.http_host,":")##variables.configBean.getServerPort()##variables.configBean.getContext()#">
<cfset var site="">

<cfif arguments.siteid neq ''>
	<cfset site=variables.settingsManager.getSite(arguments.siteid)>
	<cfset sendLoginScript =site.getSendLoginScript()/>
	<cfset contactEmail=site.getContact()/>
	<cfset contactName=site.getSite()/>
	
	<cfif left(site.getEditProfileURL(),4) eq "http">
		<cfset editProfileURL=site.getEditProfileURL()>
	<cfelse>
		<cfset editProfileURL=urlBase & site.getEditProfileURL()>
	</cfif>
		
	<cfset returnURL="#urlBase##site.getContentRenderer().getURLStem(site.getSiteID(),returnID)#">	
<cfelse>
	<cfset site=variables.settingsManager.getSite("default")>
	<cfset contactEmail=variables.configBean.getAdminEmail()/>
	<cfset contactName=variables.configBean.getTitle()/>
	
	<cfset returnURL="#urlBase##site.getContentRenderer().getURLStem(site.getSiteID(),returnID)#">
	<cfset editProfileURL =urlBase & "/admin/index.cfm?fuseaction=cEditProfile.edit">	

</cfif>


<!--- make sure that there is a ? in the editProfileURL--->
<cfif not find("?",editProfileURL)>
	<cfset editProfileURL=editProfileURL & "?">
</cfif>

<cfif not len(arguments.siteID)>
	<!--- add extra attributes --->
	<cfset editProfileURL=editProfileURL & "&siteID=#arguments.args.siteID#">
</cfif>

<!--- add extra attributes --->
<cfset editProfileURL=editProfileURL & "&returnID=#returnID#&returnUserID=#arguments.args.userID#">

<cfquery datasource="#variables.configBean.getDatasource()#"  username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
	insert into tredirects (redirectID,URL,created) values(
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#returnID#" >,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#editProfileURL#" >,
	<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
	)
</cfquery>

<cfif sendLoginScript neq ''>

<cfset theString = sendLoginScript/>
<cfset finder=refind('##.+?##',theString,1,"true")>
<cfloop condition="#finder.len[1]#">
	<cftry>
		<cfset theString=replace(theString,mid(theString, finder.pos[1], finder.len[1]),'#trim(evaluate(mid(theString, finder.pos[1], finder.len[1])))#')>
		<cfcatch>
			<cfset theString=replace(theString,mid(theString, finder.pos[1], finder.len[1]),'')>
		</cfcatch>
	</cftry>
	<cfset finder=refind('##.+?##',theString,1,"true")>
</cfloop>
<cfset sendLoginScript = theString>
	
<cfsavecontent variable="mailText">
<cfoutput>#sendLoginScript#</cfoutput>
</cfsavecontent>

<cfelseif autoresetpasswords>

<cfsavecontent variable="mailText">
<cfoutput>Dear #firstname#,

You've requested your login information be sent to you.

Username: #username#
Password: #password#

Please contact #contactEmail# if you
have any questions or comments on this process.

Thank you,

The #contactName# staff</cfoutput>
</cfsavecontent>

<cfelse>

<cfsavecontent variable="mailText">
<cfoutput>Dear #firstname#,

We received a request to reset the password associated with this
e-mail address. If you made this request, please follow the
instructions below.

(If you did not request to have your password reset you can safely
ignore this email.)

Please click the link below to access your account and reset your password:

#returnURL#

If clicking the link doesn't seem to work, you can copy and paste the
link into your browser's address window, or retype it there. Once you
have returned to #contactName#, you can then access your account and reset
your password.

Thanks for using #contactName#</cfoutput>
</cfsavecontent>

</cfif>

<cfset variables.mailer.sendText(mailText,
				arguments.sendto,
				arguments.from,
				arguments.subject,
				arguments.siteid
				) />


</cffunction>

<cffunction name="sendActivationNotification" returntype="void" output="false">
<cfargument name="userBean" type="any">

<cfset var accountactivationscript=""/>
<cfset var sendLoginScript=""/>
<cfset var mailText=""/>
<cfset var contactEmail=""/>
<cfset var contactName=""/>
<cfset var firstName=""/>
<cfset var lastName=""/>
<cfset var username=""/>
<cfset var finder=""/>
<cfset var theString=""/>

<cfset accountActivationScript = variables.settingsManager.getSite(arguments.userBean.getSiteID()).getAccountActivationScript()/>
<cfset contactEmail=variables.settingsManager.getSite(arguments.userBean.getSiteID()).getContact()/>
<cfset contactName=variables.settingsManager.getSite(arguments.userBean.getSiteID()).getSite()/>
<cfset firstName=arguments.userBean.getFname() />
<cfset lastName=arguments.userBean.getLname() />
<cfset username=arguments.userBean.getUsername() />
	
<cfif accountActivationScript neq ''>
	<cfset theString = accountActivationScript />
	<cfset finder=refind('##.+?##',theString,1,"true")>
	<cfloop condition="#finder.len[1]#">
		<cftry>
			<cfset theString=replace(theString,mid(theString, finder.pos[1], finder.len[1]),'#trim(evaluate(mid(theString, finder.pos[1], finder.len[1])))#')>
			<cfcatch>
				<cfset theString=replace(theString,mid(theString, finder.pos[1], finder.len[1]),'')>
			</cfcatch>
		</cftry>
		<cfset finder=refind('##.+?##',theString,1,"true")>
	</cfloop>
	<cfset accountActivationScript = theString/>


<cfset variables.mailer.sendText(accountActivationScript,
				arguments.userBean.getEmail(),
				variables.settingsManager.getSite(arguments.userBean.getSiteID()).getSite(),
				"Your website account at #variables.settingsManager.getSite(arguments.userBean.getSiteID()).getSite()# is now active",
				arguments.userBean.getSiteID()
				) />


</cfif>	

</cffunction>
	
<cffunction name="getRandomPassword" access="public" returntype="string" output="false">
	<cfargument name="Length" default="6" required="yes" type="numeric">
	<cfargument name="CharSet" default="Alpha" required="yes" type="string">
	<cfargument name="Ucase" default="no" required="yes" type="string">
	
	<cfset var alphaLcase = "a|c|e|g|i|k|m|o|q|s|u|w|y|b|d|f|h|j|l|n|p|r|t|v|x|z">
	<cfset var alphaUcase = "A|C|E|G|I|K|M|O|Q|S|U|W|Y|B|D|F|H|J|L|N|P|R|T|V|X|Z">
	<cfset var numeric =    "0|2|4|6|8|9|7|5|3|1">
	<cfset var ThisPass="">
	<cfset var charlist=""/>
	<cfset var thisNum=0/>
	<cfset var thisChar=""/>
	<cfset var i=0/>
	
	<cfswitch expression="#arguments.CharSet#">
	
	 <cfcase value="alpha">
	  <cfset charlist = alphaLcase>
	   <cfif arguments.UCase IS "Yes">
		<cfset charList = listappend(charlist, alphaUcase, "|")>
	   </cfif>
	 </cfcase>
	
	 <cfcase value="alphanumeric">
	  <cfset charlist = "#alphaLcase#|#numeric#">
	   <cfif arguments.UCase IS "Yes">
		<cfset charList = listappend(charlist, alphaUcase, "|")>
	   </cfif>  
	 </cfcase>
	 
	 <cfcase value="numeric">
	  <cfset charlist = numeric>
	 </cfcase>
	  
	 <cfdefaultcase><cfthrow detail="Valid values of the attribute <b>CharSet</b> are Alpha, AlphaNumeric, and Numeric"> </cfdefaultcase> 
	</cfswitch>
	
	<cfloop from="1" to="#arguments.Length#" index="i">
	 <cfset ThisNum = RandRange(1,listlen(charlist, "|"))>
	 <cfset ThisChar = ListGetAt(Charlist, ThisNum, "|")>
	 <cfset ThisPass = ListAppend(ThisPass, ThisChar, " ")>
	</cfloop>
	
	<cfreturn replace(ThisPass," ","","ALL") />
</cffunction>

<cffunction name="setUserStruct" output="false" access="public" returntype="void">
<cfargument name="user">
<cfargument name="memberships" required="true" default="">

<cfparam name="session.rememberMe" type="numeric" default="0" />
<cfparam name="session.loginAttempts" type="numeric" default="0" />
<cfparam name="session.blockLoginUntil" type="string" default="" />

<!--- clear out all existing values --->
<cfset session.mura=structNew()>

<cfif structKeyExists(arguments,"user")>
	<cfset session.mura.isLoggedIn=true>			
	<cfset session.mura.userID=arguments.user.userID>
	<cfset session.mura.username=arguments.user.username>
	<cfset session.mura.siteID=arguments.user.siteid>
	<cfset session.mura.subtype=arguments.user.subtype>
	<cfset session.mura.password=arguments.user.password>
	<cfset session.mura.fname=arguments.user.fname>
	<cfset session.mura.lname=arguments.user.lname>
	<cfset session.mura.email=arguments.user.email>
	<cfset session.mura.remoteID=arguments.user.remoteID>
	<cfset session.mura.company=arguments.user.company>
	<cfset session.mura.lastlogin=arguments.user.lastlogin>
	<cfset session.mura.passwordCreated=arguments.user.passwordCreated>
	<cfset session.mura.memberships=arguments.memberships>
<cfelse>
	<cfset session.mura.isLoggedIn=false>			
	<cfset session.mura.userID="">
	<cfset session.mura.siteID="">
	<cfset session.mura.subtype="Default">
	<cfset session.mura.username="">
	<cfset session.mura.password="">
	<cfset session.mura.fname="">
	<cfset session.mura.lname="">
	<cfset session.mura.company="">
	<cfset session.mura.lastlogin="">
	<cfset session.mura.passwordCreated="">
	<cfset session.mura.email="">
	<cfset session.mura.remoteID="">
	<cfset session.mura.memberships="">
</cfif>
</cffunction>

<cffunction name="returnLoginCheck" output="false">
<cfargument name="$">
	<cfset var rs="">
	<cfif not $.currentUser().isLoggedIn() and len($.event('returnID')) and len($.event('returnUserID'))>
		<cfquery name="rs" datasource="#variables.configBean.getDatasource()#"  username="#variables.configBean.getDBUsername()#" password="#variables.configBean.getDBPassword()#">
			select created from tredirects
			where redirectID=<cfqueryparam cfsqltype="cf_sql_varchar" value="#$.event('returnID')#" >
		</cfquery>
		<cfif rs.recordcount and rs.created gte dateAdd("d",-1,now())>
			<cfset loginByUserID($.event('returnUserID'),$.event('siteID'))>
			<cfset structDelete(session,"siteArray")>
		</cfif>
	</cfif>
</cffunction>

</cfcomponent>