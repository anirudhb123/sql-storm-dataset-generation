
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 860 and 860+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'grey' or i_color = 'medium') and 
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'gainsboro') and
        (i_units = 'Tbl' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'honeydew') and
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'cream') and
        (i_units = 'Tsp' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'bisque' or i_color = 'floral') and 
        (i_units = 'Gross' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'aquamarine' or i_color = 'metallic') and
        (i_units = 'Case' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'saddle') and
        (i_units = 'Each' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'orange') and
        (i_units = 'Unknown' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
