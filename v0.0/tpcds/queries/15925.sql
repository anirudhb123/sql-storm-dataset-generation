
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 742 and 742+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'chartreuse') and 
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'khaki' or i_color = 'blush') and
        (i_units = 'Case' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'honeydew') and
        (i_units = 'Pound' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'gainsboro') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lime' or i_color = 'navajo') and 
        (i_units = 'Lb' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'green') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'ghost') and
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'floral') and
        (i_units = 'Dram' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
