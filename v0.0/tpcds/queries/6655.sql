
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 815 and 815+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'azure' or i_color = 'blue') and 
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'firebrick') and
        (i_units = 'Lb' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'lime') and
        (i_units = 'Box' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'chocolate') and
        (i_units = 'Gross' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'peach') and 
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'forest') and
        (i_units = 'Tbl' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'honeydew') and
        (i_units = 'Dram' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'pink') and
        (i_units = 'Ounce' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
