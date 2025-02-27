
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 958 and 958+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'saddle' or i_color = 'aquamarine') and 
        (i_units = 'Unknown' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'brown') and
        (i_units = 'Tbl' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'antique') and
        (i_units = 'Case' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'goldenrod') and
        (i_units = 'Lb' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dodger' or i_color = 'linen') and 
        (i_units = 'Each' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'ghost') and
        (i_units = 'Gross' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'honeydew') and
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'ivory') and
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
