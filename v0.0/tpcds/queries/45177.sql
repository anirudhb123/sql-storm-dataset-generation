
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 679 and 679+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'cream') and 
        (i_units = 'Oz' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'sky' or i_color = 'maroon') and
        (i_units = 'Lb' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'powder') and
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'midnight') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'turquoise' or i_color = 'azure') and 
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'puff') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'saddle') and
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'green') and
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
