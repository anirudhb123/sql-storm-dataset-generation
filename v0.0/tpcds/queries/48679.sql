
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 812 and 812+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'navy') and 
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'moccasin') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'linen') and
        (i_units = 'N/A' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'antique') and
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'blanched') and 
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'smoke' or i_color = 'goldenrod') and
        (i_units = 'Bundle' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'green') and
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'maroon') and
        (i_units = 'Box' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
