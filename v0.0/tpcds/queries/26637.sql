
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 825 and 825+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'puff') and 
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'almond' or i_color = 'cyan') and
        (i_units = 'Pound' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'deep') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'violet') and
        (i_units = 'Ton' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'blue') and 
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'lemon') and
        (i_units = 'Tbl' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'hot') and
        (i_units = 'Tsp' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'cream') and
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
