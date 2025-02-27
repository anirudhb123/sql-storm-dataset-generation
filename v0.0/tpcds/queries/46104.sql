
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 780 and 780+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'pale') and 
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'almond' or i_color = 'ghost') and
        (i_units = 'Ton' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'dodger') and
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'lime') and
        (i_units = 'Dram' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'peru') and 
        (i_units = 'Pound' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'coral') and
        (i_units = 'Box' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'indian') and
        (i_units = 'Unknown' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'firebrick') and
        (i_units = 'Gram' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
