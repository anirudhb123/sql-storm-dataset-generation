
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 928 and 928+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'bisque') and 
        (i_units = 'Box' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'wheat' or i_color = 'deep') and
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'burnished') and
        (i_units = 'Gross' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'mint') and
        (i_units = 'Each' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'spring' or i_color = 'powder') and 
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'tan') and
        (i_units = 'Unknown' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'peach') and
        (i_units = 'Ounce' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'metallic') and
        (i_units = 'Dram' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
