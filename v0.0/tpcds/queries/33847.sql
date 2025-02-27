
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 694 and 694+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'frosted') and 
        (i_units = 'Dram' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'medium' or i_color = 'salmon') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'floral') and
        (i_units = 'Dozen' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'burnished') and
        (i_units = 'Ton' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'gainsboro') and 
        (i_units = 'Oz' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'maroon' or i_color = 'green') and
        (i_units = 'Gross' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'lemon') and
        (i_units = 'Tbl' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'ghost') and
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
