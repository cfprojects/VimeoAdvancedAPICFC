<!---
 
	----------THIS BLOCK MUST REMAIN INTACT--------------
	
	Name: VimeoAdvancedAPI.cfc
	Author: Alycen Vance Treloar for CF Webtools 
	Email: alycen@cfwebtools.com
	Last Updated: May 3, 2013
	Requirements: See below
	Copyright: CFWebtools 2013. All rights reserved. For personal and educational use only. Commercial use prohibited - please contact us for licensing info.
	
 --->

<cfcomponent output="false">
	
	<!--- set your variables here --->
	<cfset user_id="">
	<cfset consumer_key="">
	<cfset format="xml">
	<cfset sigmethod="HMAC-SHA1">
	<cfset version="1.0">
	<Cfset vimeoURL = 'http://vimeo.com/api/rest/v2'>
	<cfset ck = ""><!--- consumer key --->
	<cfset cs=""><!--- consumer secret --->
	<cfset oauthPath="oauth">

	<!--- oauth requirements --->
	<!--- 
		Requires installation of cfc oauth: http://oauth.riaforge.org/
	 --->
	
	
	<!--- data requirements --->
	<!--- create the following tables in your designated datasource
			
		
		create table albums(album_id int not null,
		album_title varchar(100) not null,
		album_description varchar(400) null,
		created_on datetime not null,
		total_videos int not null,
		album_url varchar(255) not null,
		video_sort_method varchar(20) null)
		
		
		
		create table videos(video_id int not null,
		embed_privacy varchar(20) null,
		is_hd bit not null default(0),
		license varchar(30) null,
		modified_date datetime not null,
		privacy varchar(20) null,
		video_title varchar(255) not null,
		video_description varchar(400) null,
		upload_date datetime not null,
		album_id int not null,
		tags varchar(255) null,
		video_url varchar(400) not null,
		video_url_mobile varchar(400) not null
		)
		
		
		
		create table thumbnails(thumbnail_id int not null,
		album_id int not null,
		height int not null,
		width int not null,
		thumbnail_url varchar(400) not null)



	
	

	 --->
	<cfset sqlDSN = "lifegate">
	
	<cffunction name="getAlbums" returntype="xml" hint="gets all albums from vimeo and returns the xml response">
		<cfset stParameters = StructNew()>
		<cfset stParameters.user_id=user_id>
		<cfset stParameters.consumer_key=consumer_key>
		<cfset stParameters.format=format>
		<cfset stParameters.oauth_signature_method=sigmethod>
		<cfset stParameters.version=version>
		<cfset stParameters.method="vimeo.albums.getAll">
		
		<!--- need nonce and timestamp --->
		<cfset oEmptyToken = CreateObject("component", "#oauthPath#.oauthtoken").createEmptyToken()>
		<cfset oConsumer = CreateObject("component", "#oauthPath#.oauthconsumer").init(sKey = ck, sSecret = cs)>
		<cfset oReqSigMethodSHA = CreateObject("component", "#oauthPath#.oauthsignaturemethod_hmac_sha1")>
		
		<cfset vReq = CreateObject("component", "#oauthPath#.oauthrequest").fromConsumerAndToken(
				oConsumer = oConsumer,
				oToken = oEmptyToken,
				sHttpMethod = "GET",
				sHttpURL = vimeoURL,
				stParameters = stParameters)>
		
		
		<cfset vReq.signRequest(
				oSignatureMethod = oReqSigMethodSHA,
				oConsumer = oConsumer,
				oToken = oEmptyToken)>
					
		<cfset p = vReq.getParameters()>
		<cfset u = vReq.getString()>

		<cfhttp method="get" url="#u#" result="rt" />
		<cfset response = rt.filecontent>
						
		<cfreturn response />
	</cffunction>
	
	<cffunction name="getVideosInAlbum" returntype="xml" hint="returns xml response from vimeo with data on videos in album id passed">
		<cfargument name="id" type="numeric" hint="the album id">
		
		<cfset stParameters = StructNew()>
		<cfset stParameters.user_id=user_id>
		<cfset stParameters.consumer_key=consumer_key>
		<cfset stParameters.format=format>
		<cfset stParameters.oauth_signature_method=sigmethod>
		<cfset stParameters.version=version>
		<cfset stParameters.method="vimeo.albums.getVideos">
		<cfset stParameters.album_id = arguments.id>
		<cfset stParameters.full_response="1">
		
		<!--- need nonce and timestamp --->
		<cfset oEmptyToken = CreateObject("component", "#oauthPath#.oauthtoken").createEmptyToken()>
		<cfset oConsumer = CreateObject("component", "#oauthPath#.oauthconsumer").init(sKey = ck, sSecret = cs)>
		<cfset oReqSigMethodSHA = CreateObject("component", "#oauthPath#.oauthsignaturemethod_hmac_sha1")>
		
		<cfset vReq = CreateObject("component", "#oauthPath#.oauthrequest").fromConsumerAndToken(
				oConsumer = oConsumer,
				oToken = oEmptyToken,
				sHttpMethod = "GET",
				sHttpURL = vimeoURL,
				stParameters = stParameters)>
		
		
		<cfset vReq.signRequest(
				oSignatureMethod = oReqSigMethodSHA,
				oConsumer = oConsumer,
				oToken = oEmptyToken)>
					
		<cfset p = vReq.getParameters()>
		<cfset u = vReq.getString()>

		<cfhttp method="get" url="#u#" result="rt" />
		<cfset response = rt.filecontent>
		
		<cfreturn response />
	</cffunction>
	
	<cffunction name="updateData" returntype="string" hint="takes XML data from vimeo and updates db table">
		
		<cfset var retStr = "">
		<!--- backup and clear existing data --->
		<cftry>
			<cfquery name="clear_backup_data" datasource="#sqlDSN#">
				drop table albums_backup
				drop table videos_backup
				drop table thumbnails_backup
			</cfquery>		
		<cfcatch type="database" />
		</cftry>
		
		<cfquery name="backup_data" datasource="#sqlDSN#">
			select * into albums_backup from albums
			select * into videos_backup from videos
			select * into thumbnails_backup from thumbnails
		</cfquery>
		
		<cfquery name="clear_data" datasource="#sqlDSN#">
			delete albums
			delete videos
			delete thumbnails
		</cfquery>
		
		<!--- start new data --->
		
		<!--- albums --->
		<cfset albumsData = XMLParse(getAlbums())>
		<cfset data = XmlSearch(albumsData,"rsp/albums")>
		<cfset totalAlbums = data[1].XmlAttributes.total>
		<cfset albumsArray = XmlSearch(albumsData,"rsp/albums/album")>
		<Cfset retStr = retStr & " #totalAlbums# albums processed. ">
		<cfset vidTotal = 0>
		
		<cfloop from="1" to="#totalAlbums#" index="a">
			<cfset thisAlbum = albumsArray[a]>
			<cfset id = thisAlbum.XmlAttributes.id>
			<cfset album_id = id>
			<cfset thisAlbumData = thisAlbum.XmlChildren><!--- album data --->
			 <!--- <cfdump var="#thisAlbumData#"><cfabort> --->
				<cfset albumSQL = "">
				<cfloop from="1" to="#arrayLen(thisAlbumData)#" index="ad">
					<!--- <cfoutput>#thisAlbumData[ad].XmlName#<br /></cfoutput> --->
					<cfif thisAlbumData[ad].XmlName EQ "thumbnail_video">
						<cfset tid = thisAlbumData[ad].XmlAttributes.id>
						<cfset th = thisAlbumData[ad].XmlChildren[2].xmlChildren><!--- thumbnail array --->
						<!--- <cfdump var="#th#" label="thumbnail array"> --->
						<cfloop from="1" to="#arrayLen(th)#" index="t">
							<cfquery name="insert_album_thumbnail" datasource="#sqlDSN#">
								insert into thumbnails(thumbnail_id,video_id,album_id,height,width,thumbnail_url)
								values
								(#tid#,null,#id#,#th[t].XmlAttributes.height#,#th[t].XmlAttributes.width#,'#th[t].XmlText#')
							</cfquery>
						</cfloop>
					<cfelseif thisAlbumData[ad].XmlName EQ "url">
						<cfset album_url = thisAlbumData[ad].XmlText>
					<cfelse>
						<!--- <cfoutput>#thisAlbumData[ad].XmlName# = #thisAlbumData[ad].XmlText#<br /></cfoutput> --->
						<cfset "#thisAlbumData[ad].XmlName#" = makeSQLsafe(thisAlbumData[ad].XmlText)>
					</cfif>

				</cfloop>
				<!--- album insert SQL --->
					<cfset albumSQL = albumSQL & " insert into albums(album_id,album_title,album_description,created_on,total_videos,album_url,video_sort_method) values">
						<!--- <cfoutput>
						album_id = #album_id#<br />
						title = #title#<br />
						description = #description#<br />
						created_on = #created_on#<br />
						total_videos = #total_videos#<br />
						album_url = #album_url#<br />
						video_sort_method = #video_sort_method#<br /><br />
						</cfoutput> --->
					<cfset albumSQL = albumSQL & "(#album_id#,'#title#','#description#','#created_on#',#total_videos#,'#album_url#','#video_sort_method#') ">
				<!--- album insert --->
				<!--- <cfdump var="#albumSQL#"><br /> --->
				<cfquery name="insert_album" datasource="#sqlDSN#">
					#preserveSingleQuotes(albumSQL)#
				</cfquery>
				
				
				<!--- videos for album --->
				<cfset aVideos = XMLParse(getVideosInAlbum(album_id))>
				<cfset data = XmlSearch(aVideos,"rsp/videos")>
				<!--- <cfdump var="#data#" label="data"><br /> --->
				<cfset totalVideos = data[1].XmlAttributes.total>
				<cfset vidTotal = vidTotal+totalVideos>
				<!--- <cfoutput>#totalVideos# in album #album_id#<br /><br /></cfoutput> --->
				<cfset videoArray = data[1].XmlChildren>
				<cfset videoSQL="">
				<cfif totalvideos gt 0>			
					<cfset videoSQL = "">
					<cfloop from="1" to="#arrayLen(videoArray)#" index="vd">
								<cfset tags="">
								
								<cfset videoData = videoArray[vd].XmlAttributes>
								<cfset videoParams = videoArray[vd].XmlChildren>
								<!--- <cfdump var="#videoParams#" label="videoParams"> --->
								<!---<cfdump var="#videoData#" label="videoData"><br /> ---> 
								<cfloop from="1" to="#arrayLen(videoParams)#" index="vp">
									<cfif videoParams[vp].XmlName EQ "tags">
										<cfset tA = videoParams[vp].XmlChildren><!--- tags array --->
										<Cfloop from="1" to="#arraylen(tA)#" index="g">
											<cfset tags = listAppend(tags,makeSQLSafe(tA[g].XmlText))>
											<!--- <cfoutput>TAG: #tA[g].XmlText#<br /></cfoutput>									</Cfloop>
											<cfoutput><h2>TAGS: #tags#</h2><br /></cfoutput>
											<cfdump var="#tA#" label="tags array"><br /> --->
										</cfloop>
									<cfelseif videoParams[vp].XmlName EQ "urls">
										<cfset uA = videoParams[vp].XmlChildren><!--- urls array --->
										<!--- <cfdump var="#uA#" label="urls array"><br /> --->
											<cfset video_url = uA[1].XmlText>
											<cfset video_url_mobile = ua[2].XmlText>	
									<cfelseif videoParams[vp].XmlName EQ "thumbnails">
										<cfset vth = videoParams[vp].XmlChildren><!--- thumbnails array, videos --->	
										<!--- <cfdump var="#vth#"><cfabort> --->	
										<cfset videoThumb = vth[2].xmlText><!--- this is the one that is 200px wide --->
									<cfelse>
										<cfset "video.#videoParams[vp].XmlName#" = videoParams[vp].XmlText>
									</cfif>
									
									<!--- <cfdump var="#video#" label="video"> --->
									
									
								</cfloop>
								
								<!--- insert SQL --->
								<cfset videoSQL = videoSQL & " insert into videos(video_id
									,embed_privacy
									,is_hd
									,license
									,modified_date
									,privacy
									,video_title
									,video_description
									,upload_date
									,album_id
									,tags
									,video_url
									,video_url_mobile
									,height
									,width
									,duration
									,videothumb) VALUES (">
	
								<cfset videoSQL = videoSQL & "#videoData.id#
									,'#videoData.embed_privacy#'
									,#videoData.is_hd#
									,'#videoData.license#'
									,'#video.modified_date#'
									,'#videoData.privacy#'
									,'#makeSQLsafe(video.title)#'
									,'#makeSQLsafe(video.description)#'	
									,'#video.upload_date#',#album_id#
									,'#tags#'
									,'#video_url#'
									,'#video_url_mobile#'
									,#video.height#
									,#video.width#
									,#video.duration#
									,'#videoThumb#')">					
					</cfloop>
				</cfif><!--- this album has videos --->			
				<!--- <cfdump var="#videoSQL#"><cfabort> --->
				<cfif len(videoSQL)>
					<cfquery name="insert_video" datasource="#sqlDSN#">
						#preserveSingleQuotes(videoSQL)#
					</cfquery>	
				</cfif>
			
			
		</cfloop>
		
	<!--- 
	ALBUMS STRUCT
	rsp
		albums on_this_page page perpage total
			album id
				title
				description
				created_on
				total_videos
				url
				video_sort_method
				thumbnail_video id owner
					thumbnail height width>url
	--->	
<!---	
	VIDEOS STRUCT
		<rsp>
			<videos on_this_page page perpage total>
				<video embed_privacy id is_hd license modified_date owner privacy title upload_date>

	 --->
	 	<cfset retStr = retStr & " #vidTotal# videos processed.">
		<cfreturn retStr />
	</cffunction>
	



	<cffunction name="makeSQLsafe" returntype="string" hint="replaces singlequotes in a string">
		<cfargument name="str_in" type="string">
		
		<cfset var str_out = arguments.str_in>
		
		<cfset str_out = replacenocase(str_out,"'","''","ALL")>
		
		<cfreturn str_out />
	</cffunction>
	


</cfcomponent>