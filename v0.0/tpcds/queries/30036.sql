
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 696 and 696+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'linen' or i_color = 'sky') and 
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'violet' or i_color = 'puff') and
        (i_units = 'Unknown' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'papaya') and
        (i_units = 'Each' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'drab') and
        (i_units = 'Tbl' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'antique') and 
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'peru' or i_color = 'cyan') and
        (i_units = 'Bunch' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'navy') and
        (i_units = 'Case' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'lemon') and
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
