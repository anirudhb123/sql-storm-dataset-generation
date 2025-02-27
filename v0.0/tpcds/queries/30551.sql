
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 670 and 670+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'linen' or i_color = 'turquoise') and 
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'sandy') and
        (i_units = 'Dram' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'spring') and
        (i_units = 'Oz' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'smoke') and
        (i_units = 'Box' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burnished' or i_color = 'orange') and 
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'dim') and
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'firebrick') and
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'chiffon') and
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
