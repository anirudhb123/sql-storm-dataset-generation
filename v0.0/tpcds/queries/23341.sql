
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 801 and 801+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'smoke' or i_color = 'firebrick') and 
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'mint' or i_color = 'grey') and
        (i_units = 'Box' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'saddle') and
        (i_units = 'Case' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'deep') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'slate') and 
        (i_units = 'Oz' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'antique') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'light') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'gainsboro') and
        (i_units = 'Each' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
