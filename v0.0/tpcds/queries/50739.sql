
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 870 and 870+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'navy') and 
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'almond' or i_color = 'midnight') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'royal') and
        (i_units = 'Ton' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'burlywood') and
        (i_units = 'Tbl' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'beige') and 
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'turquoise') and
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'azure') and
        (i_units = 'Carton' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'aquamarine') and
        (i_units = 'Gram' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
