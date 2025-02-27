
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 669 and 669+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'chiffon') and 
        (i_units = 'Carton' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'purple') and
        (i_units = 'Dram' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'grey') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'rose') and
        (i_units = 'Oz' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'chartreuse') and 
        (i_units = 'Unknown' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'ghost') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'green') and
        (i_units = 'Bundle' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'orchid') and
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
