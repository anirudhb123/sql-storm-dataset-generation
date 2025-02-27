
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 794 and 794+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'forest' or i_color = 'light') and 
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'cyan' or i_color = 'white') and
        (i_units = 'Pound' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'peach') and
        (i_units = 'Tbl' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'indian') and
        (i_units = 'Bunch' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'blush') and 
        (i_units = 'Gram' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'lime') and
        (i_units = 'Gross' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'frosted') and
        (i_units = 'Lb' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'chocolate') and
        (i_units = 'Cup' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
