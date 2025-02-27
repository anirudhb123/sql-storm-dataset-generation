
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 683 and 683+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'purple' or i_color = 'azure') and 
        (i_units = 'Ounce' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'magenta' or i_color = 'drab') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'green') and
        (i_units = 'Case' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'indian') and
        (i_units = 'N/A' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'misty' or i_color = 'chocolate') and 
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'maroon') and
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'floral') and
        (i_units = 'Unknown' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'turquoise') and
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
