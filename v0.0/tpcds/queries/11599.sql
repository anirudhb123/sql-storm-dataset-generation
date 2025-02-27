
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 770 and 770+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'smoke') and 
        (i_units = 'Tbl' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'snow' or i_color = 'linen') and
        (i_units = 'Bunch' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'grey') and
        (i_units = 'Unknown' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'chiffon') and
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'red' or i_color = 'ivory') and 
        (i_units = 'Pound' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'saddle' or i_color = 'slate') and
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'hot') and
        (i_units = 'Tsp' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'firebrick') and
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
