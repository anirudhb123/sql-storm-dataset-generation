
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 739 and 739+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'blue') and 
        (i_units = 'Bunch' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'ghost' or i_color = 'medium') and
        (i_units = 'Dram' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'firebrick') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'dark') and
        (i_units = 'Cup' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'grey') and 
        (i_units = 'Ton' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'lime') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'misty') and
        (i_units = 'Tbl' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'pale') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
