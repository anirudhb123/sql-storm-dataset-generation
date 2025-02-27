
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 844 and 844+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sandy' or i_color = 'misty') and 
        (i_units = 'Oz' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'white') and
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'ivory') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'maroon') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'drab') and 
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'salmon') and
        (i_units = 'Box' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'sky') and
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'light') and
        (i_units = 'Dozen' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
