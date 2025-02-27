
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 767 and 767+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'rosy') and 
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'hot') and
        (i_units = 'Case' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'pale') and
        (i_units = 'Bunch' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'sky') and
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'maroon' or i_color = 'firebrick') and 
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'cornflower') and
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'beige') and
        (i_units = 'Ton' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'forest') and
        (i_units = 'Pallet' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
