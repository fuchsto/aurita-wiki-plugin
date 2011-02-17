
alter table media_asset version add mime varchar(100) not null default '';
alter table media_asset version add filesize integer not null default 0;
alter table media_asset version add checksum varchar(32);

