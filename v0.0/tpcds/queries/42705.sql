
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 828 and 828+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'hot') and 
        (i_units = 'Dozen' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'tomato' or i_color = 'thistle') and
        (i_units = 'Cup' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'steel') and
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'coral') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'snow') and 
        (i_units = 'Bundle' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'lawn') and
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'pink') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'ivory') and
        (i_units = 'Unknown' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
