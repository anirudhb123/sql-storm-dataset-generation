
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 829 and 829+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'papaya') and 
        (i_units = 'Carton' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'firebrick' or i_color = 'pale') and
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'olive') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'maroon') and
        (i_units = 'Ounce' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'snow' or i_color = 'pink') and 
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'blanched') and
        (i_units = 'Case' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'smoke') and
        (i_units = 'Unknown' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'cornsilk') and
        (i_units = 'Bunch' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
