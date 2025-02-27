
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 868 and 868+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ghost' or i_color = 'bisque') and 
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'almond' or i_color = 'drab') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'dim') and
        (i_units = 'Pallet' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'puff') and
        (i_units = 'Unknown' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'chartreuse') and 
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'maroon') and
        (i_units = 'Each' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'steel') and
        (i_units = 'Tsp' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'violet') and
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
