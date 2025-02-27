
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 685 and 685+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'moccasin') and 
        (i_units = 'Dozen' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'ghost') and
        (i_units = 'Tbl' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'pale') and
        (i_units = 'Pound' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'pink') and
        (i_units = 'Oz' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'maroon') and 
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chocolate' or i_color = 'misty') and
        (i_units = 'Cup' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'red' or i_color = 'drab') and
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'orchid') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
