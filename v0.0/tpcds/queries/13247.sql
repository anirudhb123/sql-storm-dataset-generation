
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 782 and 782+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ivory' or i_color = 'violet') and 
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'floral') and
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'peach') and
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'cornflower') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'spring') and 
        (i_units = 'N/A' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'brown' or i_color = 'antique') and
        (i_units = 'Box' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'chiffon') and
        (i_units = 'Cup' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'royal') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
