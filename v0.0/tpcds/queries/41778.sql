
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 727 and 727+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'black') and 
        (i_units = 'Ounce' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'maroon') and
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'blue') and
        (i_units = 'Case' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'steel') and
        (i_units = 'Oz' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pink' or i_color = 'lime') and 
        (i_units = 'Tbl' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'drab') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'dark') and
        (i_units = 'Dram' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'orange') and
        (i_units = 'Box' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
