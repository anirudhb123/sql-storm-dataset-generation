
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 813 and 813+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sandy' or i_color = 'deep') and 
        (i_units = 'N/A' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'dim') and
        (i_units = 'Dozen' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'lavender') and
        (i_units = 'Box' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'goldenrod') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'green') and 
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'brown' or i_color = 'peach') and
        (i_units = 'Dram' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'orange') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'moccasin') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
