
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 736 and 736+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'forest') and 
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'hot') and
        (i_units = 'Each' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'chartreuse') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'chocolate') and
        (i_units = 'Pallet' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'green') and 
        (i_units = 'Ounce' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'tan') and
        (i_units = 'Dozen' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'chiffon') and
        (i_units = 'Dram' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'aquamarine') and
        (i_units = 'Ton' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
