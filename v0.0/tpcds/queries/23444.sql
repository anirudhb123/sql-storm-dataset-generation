
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 810 and 810+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'wheat') and 
        (i_units = 'Ounce' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'powder' or i_color = 'moccasin') and
        (i_units = 'Case' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'sky') and
        (i_units = 'Each' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'saddle') and
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'deep' or i_color = 'chiffon') and 
        (i_units = 'Cup' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'black') and
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'forest') and
        (i_units = 'Bundle' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'tan') and
        (i_units = 'Tbl' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
