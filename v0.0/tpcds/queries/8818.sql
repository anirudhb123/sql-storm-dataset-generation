
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 801 and 801+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'papaya') and 
        (i_units = 'Tbl' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'cream' or i_color = 'blush') and
        (i_units = 'Dozen' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'saddle' or i_color = 'chocolate') and
        (i_units = 'Ounce' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'lawn') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burnished' or i_color = 'aquamarine') and 
        (i_units = 'N/A' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'royal') and
        (i_units = 'Tsp' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'pale') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'red') and
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
