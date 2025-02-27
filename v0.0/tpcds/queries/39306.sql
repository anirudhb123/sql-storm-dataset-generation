
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 957 and 957+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'dodger') and 
        (i_units = 'Dozen' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'ivory') and
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'ghost') and
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'blanched') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'brown') and 
        (i_units = 'Pound' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'floral') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'powder') and
        (i_units = 'Bunch' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'coral') and
        (i_units = 'Cup' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
