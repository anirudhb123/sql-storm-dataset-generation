
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 896 and 896+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'purple' or i_color = 'honeydew') and 
        (i_units = 'Unknown' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'lemon') and
        (i_units = 'Ton' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'dark') and
        (i_units = 'Bundle' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'pale') and
        (i_units = 'Carton' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'violet') and 
        (i_units = 'Case' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'plum' or i_color = 'navy') and
        (i_units = 'Lb' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'cornsilk') and
        (i_units = 'Bunch' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'orchid') and
        (i_units = 'Dram' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
