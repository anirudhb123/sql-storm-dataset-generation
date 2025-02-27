
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 973 and 973+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'cyan') and 
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'misty') and
        (i_units = 'Lb' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'orange') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'forest') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'hot') and 
        (i_units = 'Ton' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'white' or i_color = 'honeydew') and
        (i_units = 'Dozen' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'midnight') and
        (i_units = 'Case' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'lime') and
        (i_units = 'Pound' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
