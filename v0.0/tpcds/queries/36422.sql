
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 726 and 726+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'seashell') and 
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'chiffon') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'yellow' or i_color = 'honeydew') and
        (i_units = 'Cup' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'aquamarine') and
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'firebrick') and 
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'mint') and
        (i_units = 'Bundle' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'steel') and
        (i_units = 'Bunch' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'powder') and
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
