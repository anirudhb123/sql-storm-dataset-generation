
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 670 and 670+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'honeydew') and 
        (i_units = 'Dozen' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'hot' or i_color = 'beige') and
        (i_units = 'Bundle' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'navajo') and
        (i_units = 'Case' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'snow') and
        (i_units = 'Dram' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'plum' or i_color = 'chiffon') and 
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'blush') and
        (i_units = 'Ounce' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'grey') and
        (i_units = 'Pallet' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'floral') and
        (i_units = 'Cup' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
