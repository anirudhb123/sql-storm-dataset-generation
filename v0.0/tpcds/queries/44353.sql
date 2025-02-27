
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 840 and 840+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dodger' or i_color = 'linen') and 
        (i_units = 'Bundle' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'mint') and
        (i_units = 'Tbl' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'indian' or i_color = 'blue') and
        (i_units = 'Pound' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'cream') and
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'frosted') and 
        (i_units = 'Lb' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'peru' or i_color = 'misty') and
        (i_units = 'Case' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'chartreuse') and
        (i_units = 'Cup' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'royal') and
        (i_units = 'Each' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
