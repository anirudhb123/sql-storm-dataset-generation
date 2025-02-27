
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 899 and 899+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'seashell' or i_color = 'maroon') and 
        (i_units = 'Oz' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'blanched') and
        (i_units = 'Carton' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'dark') and
        (i_units = 'Cup' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'olive') and
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'smoke' or i_color = 'pink') and 
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'drab') and
        (i_units = 'Dozen' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'chiffon') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'salmon') and
        (i_units = 'Lb' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
