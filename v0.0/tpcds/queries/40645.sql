
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 770 and 770+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'brown') and 
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'peach' or i_color = 'ghost') and
        (i_units = 'Case' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'mint') and
        (i_units = 'Lb' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'floral') and
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'steel' or i_color = 'seashell') and 
        (i_units = 'N/A' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'violet') and
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'grey') and
        (i_units = 'Bunch' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'maroon') and
        (i_units = 'Tsp' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
