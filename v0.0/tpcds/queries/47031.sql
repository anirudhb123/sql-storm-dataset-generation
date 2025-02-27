
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 881 and 881+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'peru') and 
        (i_units = 'Ounce' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'ghost' or i_color = 'blush') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'aquamarine') and
        (i_units = 'Lb' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'purple') and
        (i_units = 'Bundle' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'navy') and 
        (i_units = 'Bunch' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'saddle') and
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'midnight') and
        (i_units = 'Carton' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'floral') and
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
