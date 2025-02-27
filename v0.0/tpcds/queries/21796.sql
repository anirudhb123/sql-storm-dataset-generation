
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 798 and 798+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rosy' or i_color = 'blush') and 
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'purple' or i_color = 'peach') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'deep') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'brown') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navy' or i_color = 'sky') and 
        (i_units = 'Box' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'dim' or i_color = 'azure') and
        (i_units = 'Ounce' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'cornflower') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'thistle') and
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
