
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 975 and 975+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'violet') and 
        (i_units = 'Gram' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'orchid') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'purple') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'green') and
        (i_units = 'Cup' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pink' or i_color = 'navajo') and 
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'bisque') and
        (i_units = 'Pound' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'indian') and
        (i_units = 'Dram' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'magenta') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
