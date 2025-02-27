
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 957 and 957+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'drab' or i_color = 'hot') and 
        (i_units = 'N/A' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'steel' or i_color = 'slate') and
        (i_units = 'Ounce' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'bisque') and
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'ghost') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'blanched') and 
        (i_units = 'Pallet' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'beige') and
        (i_units = 'Gross' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'brown') and
        (i_units = 'Each' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'powder') and
        (i_units = 'Gram' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
