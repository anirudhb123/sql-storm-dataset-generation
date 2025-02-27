
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 855 and 855+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'lawn') and 
        (i_units = 'Tbl' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'bisque') and
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'lemon') and
        (i_units = 'Bunch' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'burnished') and
        (i_units = 'Bundle' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'moccasin' or i_color = 'ivory') and 
        (i_units = 'Oz' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'royal' or i_color = 'frosted') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'dim') and
        (i_units = 'Dozen' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'pale') and
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
