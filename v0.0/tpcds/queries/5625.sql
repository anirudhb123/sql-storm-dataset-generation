
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 786 and 786+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'salmon' or i_color = 'violet') and 
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'turquoise' or i_color = 'cream') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'snow') and
        (i_units = 'Gram' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'blue') and
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'pink') and 
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'cyan') and
        (i_units = 'Oz' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'chocolate') and
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'navajo' or i_color = 'dodger') and
        (i_units = 'Carton' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
