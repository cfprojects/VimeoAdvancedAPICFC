Requires installation of cfc oauth: http://oauth.riaforge.org/

Data Requirements:
Create the following tables in your designated datasource
         
      
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