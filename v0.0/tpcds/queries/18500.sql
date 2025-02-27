
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 855 and 855+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'misty') and 
        (i_units = 'Each' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cyan' or i_color = 'white') and
        (i_units = 'Dozen' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'goldenrod') and
        (i_units = 'Pound' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'navajo') and
        (i_units = 'Ton' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'lace') and 
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'ghost') and
        (i_units = 'Cup' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'chartreuse') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'black') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
