
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 918 and 918+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'almond' or i_color = 'bisque') and 
        (i_units = 'Carton' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'tomato') and
        (i_units = 'Cup' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'light') and
        (i_units = 'Unknown' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'frosted') and
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'medium') and 
        (i_units = 'Each' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'chocolate') and
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'violet') and
        (i_units = 'Tsp' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'dim') and
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
