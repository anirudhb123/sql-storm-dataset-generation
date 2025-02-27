
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 711 and 711+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'beige') and 
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'green') and
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'burnished') and
        (i_units = 'Box' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'white') and
        (i_units = 'Tsp' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pink' or i_color = 'cyan') and 
        (i_units = 'Ton' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'deep') and
        (i_units = 'Pound' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'seashell') and
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'chartreuse') and
        (i_units = 'Carton' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
