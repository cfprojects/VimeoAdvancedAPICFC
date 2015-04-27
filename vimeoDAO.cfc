<cfcomponent output="false">

	<cfset sqlDSN = "lifegate">
	
	<!--- albums --->
	<cffunction name="getAlbums" returntype="query">
		<cfargument name="id" type="numeric" default="0" hint="optional">
		
		<cfquery name="qry_getAlbums" datasource="#sqlDSN#">
			select * from
			albums (nolock)
			<cfif arguments.id NEQ 0>
			WHERE album_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
			</cfif>
		</cfquery>
		
		<cfreturn qry_getAlbums />
	</cffunction>


	<!--- videos --->
	<cffunction name="getVideos" returntype="query">
		<cfargument name="id" type="numeric" default="0">
		<cfargument name="album_id" type="numeric" default="0">
		
		<cfquery name="qry_getVideos" datasource="#sqlDSN#">
			select * from
			videos (nolock)
			WHERE 1 =1 
			<cfif arguments.id NEQ 0>
			AND video_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
			</cfif>
			<Cfif arguments.album_id NEQ 0>
			AND album_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.album_id#">
			</Cfif>
						
		</cfquery>
		
		<cfreturn qry_getVideos />
	</cffunction>


	<!--- thumbnails --->
	<cffunction name="getThumbnails" returntype="query">
		<cfargument name="id" type="numeric" default="0" hint="album id. optional">
		
		<cfquery name="qry_getThumbnails" datasource="#sqlDSN#">
			select * from
			thumbnails (nolock)
			<cfif arguments.id NEQ 0>
			WHERE album_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.id#">
			</cfif>
		</cfquery>
		
		<cfreturn qry_getThumbnails />
	</cffunction>
	

	<cffunction name="getAllData" returntype="query">
		<CFARGUMENT NAME="ALBUM_ID" TYPE="NUMERIC" DEFAULT="0">
		
		<cfquery name="qry_getAllData" datasource="#sqlDSN#">
			select 
			a.album_id
			,a.album_title
			,a.album_description
			,a.created_on
			,a.total_videos
			,a.album_url
			,a.video_sort_method
			,v.video_id
			,v.embed_privacy
			,v.is_hd
			,v.license
			,v.modified_date
			,v.privacy
			,v.video_title
			,v.video_description
			,v.upload_date
			,v.tags
			,v.video_url
			,v.video_url_mobile
			,t.thumbnail_id
			,t.height
			,t.width
			,t.thumbnail_url			

			from albums a (nolock)
			join videos v on v.album_id = a.album_id
			join thumbnails t on t.album_id = a.album_id
			WHERE v.privacy = 'anybody'
			<cfif arguments.album_id NEQ 0>
			AND a.album_id = <cfqueryparam cfsqltype="cf_sql_integer" value="#arguments.album_id#">
			</cfif>
			order by a.created_on,v.upload_date desc
		</cfquery>
	
		<cfreturn qry_getAllData />
	</cffunction>


	<cffunction name="getAllAlbumsAndVideos" returntype="query">
	
		<cfquery name="qry_getAllAlbumsAndVideos" datasource="#sqlDSN#">
			select * from vimeoData
			order by albumid,VIDEOUPLOADDATE desc
		</cfquery>
		
	
	
		<cfreturn qry_getAllAlbumsAndVideos />
	</cffunction>

	<cffunction name="search" returntype="query" hint="takes search params and returns results">
		<cfargument name="album_title" type="string" default="">
		<cfargument name="video_title" type="string" default="">
		<cfargument name="tags" type="string" default="" hint="can be a list">
	
		<cfquery name="searchRs" datasource="#sqlDSN#">
			select *
			from
			vimeoData 
			WHERE
			1=1
			<cfif len(arguments.album_title)>
				AND album_title like '%#arguments.album_title#%'
			</cfif>
			<cfif len(arguments.video_title)>
				AND video_title like '%#arguments.video_title#%'
			</cfif>
			<cfif len(arguments.tags)>
				AND tags like '%#arguments.tags#%'
			</cfif>
		</cfquery>
	
		<cfreturn searchRs />
	</cffunction>

</cfcomponent>