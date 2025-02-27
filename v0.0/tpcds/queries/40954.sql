
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 969 and 969+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'almond' or i_color = 'olive') and 
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'midnight' or i_color = 'royal') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'pale') and
        (i_units = 'Tsp' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'salmon') and
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blanched' or i_color = 'seashell') and 
        (i_units = 'Box' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'light' or i_color = 'purple') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'brown') and
        (i_units = 'Lb' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'floral') and
        (i_units = 'Tbl' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
