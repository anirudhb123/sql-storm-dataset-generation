
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 861 and 861+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lace' or i_color = 'white') and 
        (i_units = 'Ounce' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'black') and
        (i_units = 'Pallet' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'blue') and
        (i_units = 'Tbl' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'firebrick') and
        (i_units = 'Lb' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'purple' or i_color = 'pale') and 
        (i_units = 'Dozen' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'forest') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'chiffon') and
        (i_units = 'Pound' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'moccasin') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
