
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 911 and 911+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lace' or i_color = 'forest') and 
        (i_units = 'Bundle' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'blanched') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'slate') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'olive') and
        (i_units = 'Bunch' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'frosted') and 
        (i_units = 'Ton' or i_units = 'Lb') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'dark' or i_color = 'drab') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'navajo') and
        (i_units = 'Cup' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'gainsboro') and
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
