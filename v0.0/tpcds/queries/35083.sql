
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 913 and 913+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'snow') and 
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'chocolate') and
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'blanched') and
        (i_units = 'Dozen' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'purple') and
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peach' or i_color = 'plum') and 
        (i_units = 'Carton' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'frosted' or i_color = 'burlywood') and
        (i_units = 'Lb' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'salmon') and
        (i_units = 'Tbl' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'cornsilk') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
