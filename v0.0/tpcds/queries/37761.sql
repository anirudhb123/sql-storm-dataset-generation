
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 954 and 954+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'khaki' or i_color = 'navy') and 
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'plum') and
        (i_units = 'Tbl' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'blanched') and
        (i_units = 'Unknown' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'linen') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'white') and 
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'spring' or i_color = 'aquamarine') and
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'lawn') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'coral') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
