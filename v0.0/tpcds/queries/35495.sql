
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 959 and 959+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'firebrick' or i_color = 'floral') and 
        (i_units = 'Bundle' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'magenta' or i_color = 'navy') and
        (i_units = 'Dozen' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'lace') and
        (i_units = 'Case' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'burnished') and
        (i_units = 'Carton' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'brown') and 
        (i_units = 'Bunch' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'navajo' or i_color = 'dodger') and
        (i_units = 'Cup' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'gainsboro') and
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'honeydew') and
        (i_units = 'Pallet' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
