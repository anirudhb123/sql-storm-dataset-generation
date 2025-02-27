
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 859 and 859+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'lace') and 
        (i_units = 'Cup' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'navajo') and
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'medium') and
        (i_units = 'Bunch' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'metallic') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'thistle') and 
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'olive' or i_color = 'purple') and
        (i_units = 'Case' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'linen') and
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'honeydew') and
        (i_units = 'Pallet' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
