
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 924 and 924+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'honeydew' or i_color = 'rose') and 
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'burnished' or i_color = 'midnight') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'cornsilk') and
        (i_units = 'Each' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'pale') and
        (i_units = 'Tsp' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'maroon') and 
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'forest') and
        (i_units = 'Box' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'lime') and
        (i_units = 'Carton' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'frosted') and
        (i_units = 'Gram' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
