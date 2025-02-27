
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 738 and 738+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'hot') and 
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'salmon') and
        (i_units = 'N/A' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'steel') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'deep') and
        (i_units = 'Cup' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'tomato') and 
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'pink' or i_color = 'ivory') and
        (i_units = 'Dram' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'blue') and
        (i_units = 'Ton' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'snow') and
        (i_units = 'Tbl' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
