
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 976 and 976+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'snow') and 
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lawn' or i_color = 'chiffon') and
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'dodger') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'chartreuse') and
        (i_units = 'Unknown' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'powder') and 
        (i_units = 'Ounce' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'forest') and
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'thistle') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'green') and
        (i_units = 'Each' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
