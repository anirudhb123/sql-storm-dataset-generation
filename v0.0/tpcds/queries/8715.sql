
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 873 and 873+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'moccasin') and 
        (i_units = 'Case' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'hot' or i_color = 'orchid') and
        (i_units = 'Pound' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'violet') and
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'frosted') and
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'maroon' or i_color = 'peru') and 
        (i_units = 'Bunch' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'slate') and
        (i_units = 'Dozen' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'ivory') and
        (i_units = 'Unknown' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'forest') and
        (i_units = 'Lb' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
