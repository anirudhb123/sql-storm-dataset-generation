
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 685 and 685+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blanched' or i_color = 'pink') and 
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'firebrick' or i_color = 'spring') and
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'burlywood') and
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'dodger') and
        (i_units = 'Box' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'coral' or i_color = 'dim') and 
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'gainsboro') and
        (i_units = 'Dram' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'drab') and
        (i_units = 'Bundle' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'purple') and
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
