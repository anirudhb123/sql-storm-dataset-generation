
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 813 and 813+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'papaya') and 
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'snow' or i_color = 'chiffon') and
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'lemon') and
        (i_units = 'Bundle' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'tomato') and
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'saddle') and 
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'rosy' or i_color = 'cyan') and
        (i_units = 'Lb' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'ghost') and
        (i_units = 'Tsp' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'olive') and
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
