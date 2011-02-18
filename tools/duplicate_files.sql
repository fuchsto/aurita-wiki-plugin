select sum(dups.kib)/1024 as mb from ( 
  select m1.media_asset_id, m2.media_asset_id, m1.checksum, m2.checksum, m1.filesize/1024 as kib
  from media_asset m1, media_asset m2 
  where m1.checksum = m2.checksum 
  and m1.media_asset_id != m2.media_asset_id 
  and m1.asset_id not in ( 
    select asset_id from asset join content using ( content_id ) where deleted = 't' 
  ) 
  order by m1.checksum asc, m1.media_asset_id asc
) as dups;
