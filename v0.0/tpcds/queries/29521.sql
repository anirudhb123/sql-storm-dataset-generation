
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 975 and 975+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'rosy') and 
        (i_units = 'Carton' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'dim') and
        (i_units = 'Tbl' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'hot') and
        (i_units = 'Case' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'navy') and
        (i_units = 'Cup' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'ivory') and 
        (i_units = 'Lb' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'lemon') and
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'forest') and
        (i_units = 'Dozen' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'medium') and
        (i_units = 'Pallet' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
