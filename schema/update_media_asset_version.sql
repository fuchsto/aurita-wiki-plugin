
alter table media_asset_version add mime varchar(100) not null default '';
alter table media_asset_version add filesize integer not null default 0;
alter table media_asset_version add checksum varchar(32);

update content set version = version+1 where version != 0; 
