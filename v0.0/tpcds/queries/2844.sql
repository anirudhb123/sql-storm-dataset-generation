
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 817 and 817+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'thistle' or i_color = 'navajo') and 
        (i_units = 'Dozen' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'medium') and
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'linen') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'light') and
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'sky') and 
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'dodger') and
        (i_units = 'Cup' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'ghost') and
        (i_units = 'Tbl' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'lawn') and
        (i_units = 'Pound' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
