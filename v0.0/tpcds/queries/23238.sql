
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 873 and 873+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'beige') and 
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'salmon') and
        (i_units = 'Lb' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'purple') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'indian') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'seashell') and 
        (i_units = 'Gram' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'chocolate') and
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'saddle') and
        (i_units = 'Bundle' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'moccasin') and
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
