
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 722 and 722+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'saddle' or i_color = 'khaki') and 
        (i_units = 'Lb' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'peru' or i_color = 'cornsilk') and
        (i_units = 'Ounce' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'puff') and
        (i_units = 'Case' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'dim') and
        (i_units = 'Pallet' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'plum' or i_color = 'burlywood') and 
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'gainsboro') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'drab') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'orchid') and
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
