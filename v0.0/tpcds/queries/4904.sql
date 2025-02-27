
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 875 and 875+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'steel') and 
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'antique' or i_color = 'deep') and
        (i_units = 'Pallet' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'sandy') and
        (i_units = 'Box' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'metallic') and
        (i_units = 'Each' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'tan') and 
        (i_units = 'Tbl' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'midnight') and
        (i_units = 'Lb' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'lemon') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'dark') and
        (i_units = 'Ounce' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
