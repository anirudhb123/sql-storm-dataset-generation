
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 826 and 826+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lawn' or i_color = 'burlywood') and 
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'forest') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'blanched') and
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'light') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ghost' or i_color = 'firebrick') and 
        (i_units = 'Pound' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'cyan') and
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'purple') and
        (i_units = 'Case' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'peru') and
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
