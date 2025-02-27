
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 867 and 867+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peach' or i_color = 'blue') and 
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'sienna' or i_color = 'sky') and
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'lace') and
        (i_units = 'Tbl' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'lavender') and
        (i_units = 'Case' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orange' or i_color = 'blush') and 
        (i_units = 'Bundle' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'seashell') and
        (i_units = 'Dozen' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'dodger') and
        (i_units = 'Unknown' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'spring') and
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
