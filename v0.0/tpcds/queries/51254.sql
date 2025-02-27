
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 925 and 925+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'powder' or i_color = 'purple') and 
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'almond' or i_color = 'sandy') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'frosted') and
        (i_units = 'Pallet' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'orange') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'saddle' or i_color = 'indian') and 
        (i_units = 'Carton' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'khaki' or i_color = 'puff') and
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'royal') and
        (i_units = 'Tbl' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'dark') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
