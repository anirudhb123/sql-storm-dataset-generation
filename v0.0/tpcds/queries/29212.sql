
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 857 and 857+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'brown') and 
        (i_units = 'Pallet' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'metallic') and
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'dark') and
        (i_units = 'Unknown' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'black') and
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'gainsboro' or i_color = 'steel') and 
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'cornsilk') and
        (i_units = 'Cup' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'deep') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'burlywood') and
        (i_units = 'Carton' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
