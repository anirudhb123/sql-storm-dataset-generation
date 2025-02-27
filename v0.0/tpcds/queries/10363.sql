
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 885 and 885+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'metallic' or i_color = 'khaki') and 
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'maroon') and
        (i_units = 'Unknown' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'wheat') and
        (i_units = 'Gross' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'floral') and
        (i_units = 'Dram' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'light') and 
        (i_units = 'Tbl' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'almond' or i_color = 'black') and
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'deep') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'tomato') and
        (i_units = 'Ounce' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
