
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 885 and 885+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'burnished') and 
        (i_units = 'Pallet' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'blanched') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sienna' or i_color = 'olive') and
        (i_units = 'Case' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'firebrick') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'aquamarine') and 
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'honeydew') and
        (i_units = 'Tbl' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'pale') and
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'metallic') and
        (i_units = 'Tsp' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
