
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 885 and 885+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'goldenrod') and 
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'bisque') and
        (i_units = 'Bunch' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'hot') and
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'thistle') and
        (i_units = 'Pallet' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'moccasin' or i_color = 'spring') and 
        (i_units = 'Tsp' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'pale') and
        (i_units = 'N/A' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'peach') and
        (i_units = 'Dram' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'pink') and
        (i_units = 'Oz' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
