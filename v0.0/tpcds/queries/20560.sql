
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 913 and 913+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'steel') and 
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'navy') and
        (i_units = 'N/A' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'snow') and
        (i_units = 'Lb' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'rose') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'gainsboro' or i_color = 'lemon') and 
        (i_units = 'Bunch' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'seashell' or i_color = 'drab') and
        (i_units = 'Unknown' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'goldenrod') and
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'metallic') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
