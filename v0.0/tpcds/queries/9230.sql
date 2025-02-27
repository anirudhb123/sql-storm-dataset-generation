
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 928 and 928+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'dodger') and 
        (i_units = 'Gross' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'almond') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'peach') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'bisque') and
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lemon' or i_color = 'moccasin') and 
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'medium' or i_color = 'honeydew') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'green') and
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'lime') and
        (i_units = 'Ton' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
