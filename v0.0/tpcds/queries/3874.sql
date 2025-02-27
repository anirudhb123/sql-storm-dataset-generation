
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 846 and 846+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'navy') and 
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'blue') and
        (i_units = 'Tsp' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'brown') and
        (i_units = 'Ton' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'sienna') and
        (i_units = 'Carton' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'grey' or i_color = 'drab') and 
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'powder' or i_color = 'forest') and
        (i_units = 'Pound' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'midnight' or i_color = 'beige') and
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'deep') and
        (i_units = 'Tbl' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
