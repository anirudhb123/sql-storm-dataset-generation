
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 872 and 872+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'moccasin') and 
        (i_units = 'Case' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'light') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'blanched') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'linen') and
        (i_units = 'Oz' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'steel') and 
        (i_units = 'N/A' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'orange' or i_color = 'chocolate') and
        (i_units = 'Carton' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'chiffon') and
        (i_units = 'Pound' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'peru') and
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
