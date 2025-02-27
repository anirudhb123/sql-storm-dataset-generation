
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 915 and 915+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lace' or i_color = 'violet') and 
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'turquoise') and
        (i_units = 'Carton' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'powder' or i_color = 'hot') and
        (i_units = 'Lb' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'forest') and
        (i_units = 'Oz' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'aquamarine' or i_color = 'papaya') and 
        (i_units = 'Each' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lavender' or i_color = 'drab') and
        (i_units = 'Ounce' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'metallic') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'dim') and
        (i_units = 'Pound' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
