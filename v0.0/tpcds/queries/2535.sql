
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 699 and 699+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'coral') and 
        (i_units = 'Dram' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'rosy' or i_color = 'gainsboro') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'salmon') and
        (i_units = 'Case' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'indian') and
        (i_units = 'Box' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'spring') and 
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'beige') and
        (i_units = 'Cup' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'red') and
        (i_units = 'Dozen' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'brown') and
        (i_units = 'Bunch' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
