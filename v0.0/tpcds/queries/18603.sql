
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 783 and 783+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'honeydew') and 
        (i_units = 'Gross' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'hot' or i_color = 'moccasin') and
        (i_units = 'Tsp' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'firebrick') and
        (i_units = 'Pound' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'floral') and
        (i_units = 'Case' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sienna' or i_color = 'blue') and 
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'cyan') and
        (i_units = 'Ton' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'gainsboro') and
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'forest') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
