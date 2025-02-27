
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 946 and 946+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'yellow' or i_color = 'brown') and 
        (i_units = 'Bunch' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'frosted') and
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'black') and
        (i_units = 'Pound' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'royal') and
        (i_units = 'Carton' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'light' or i_color = 'blue') and 
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'violet' or i_color = 'almond') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'red') and
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'lemon') and
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
