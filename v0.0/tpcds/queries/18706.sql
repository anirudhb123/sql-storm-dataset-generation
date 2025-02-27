
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 711 and 711+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'indian' or i_color = 'linen') and 
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'slate') and
        (i_units = 'Unknown' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'medium') and
        (i_units = 'Lb' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'burnished') and
        (i_units = 'Bundle' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tomato' or i_color = 'blush') and 
        (i_units = 'Tbl' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'chocolate') and
        (i_units = 'Gross' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'turquoise') and
        (i_units = 'Box' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'black') and
        (i_units = 'Ton' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
