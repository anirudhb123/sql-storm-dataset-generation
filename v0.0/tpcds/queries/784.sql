
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 759 and 759+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blue' or i_color = 'royal') and 
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'purple') and
        (i_units = 'N/A' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'lace') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'saddle') and
        (i_units = 'Tsp' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'spring' or i_color = 'mint') and 
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chocolate' or i_color = 'beige') and
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'magenta') and
        (i_units = 'Dram' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'slate') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
