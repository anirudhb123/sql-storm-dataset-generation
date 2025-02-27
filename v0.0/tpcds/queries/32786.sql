
-- end query 30 in stream 0 using template query59.tpl
-- start query 31 in stream 0 using template query37.tpl
select  i_item_id
       ,i_item_desc
       ,i_current_price
 from item, inventory, date_dim, catalog_sales
 where i_current_price between 52 and 52 + 30
 and inv_item_sk = i_item_sk
 and d_date_sk=inv_date_sk
 and d_date between cast('2000-07-13' as date) and (cast('2000-07-13' as date) +  interval '60' day)
 and i_manufact_id in (968,738,728,930)
 and inv_quantity_on_hand between 100 and 500
 and cs_item_sk = i_item_sk
 group by i_item_id,i_item_desc,i_current_price
 order by i_item_id
 limit 100;
