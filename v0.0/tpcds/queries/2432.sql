
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 771 and 771+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'turquoise') and 
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'aquamarine') and
        (i_units = 'Bunch' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'coral') and
        (i_units = 'Pallet' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'drab') and
        (i_units = 'N/A' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'thistle' or i_color = 'smoke') and 
        (i_units = 'Gram' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'midnight') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'linen') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'red') and
        (i_units = 'Lb' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
