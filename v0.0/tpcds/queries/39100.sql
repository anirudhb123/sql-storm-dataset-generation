
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 767 and 767+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orange' or i_color = 'papaya') and 
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'white') and
        (i_units = 'Ton' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'dark') and
        (i_units = 'Lb' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'goldenrod') and
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'powder' or i_color = 'honeydew') and 
        (i_units = 'Carton' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'salmon' or i_color = 'mint') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'brown') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'coral') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
