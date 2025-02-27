
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 927 and 927+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'ghost') and 
        (i_units = 'Case' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'chiffon') and
        (i_units = 'Each' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'floral') and
        (i_units = 'Dram' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'hot') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'yellow' or i_color = 'tomato') and 
        (i_units = 'Unknown' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'linen' or i_color = 'spring') and
        (i_units = 'Ounce' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'snow') and
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'sky' or i_color = 'forest') and
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
