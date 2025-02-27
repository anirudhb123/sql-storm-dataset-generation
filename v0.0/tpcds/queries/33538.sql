
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 829 and 829+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'beige') and 
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'violet' or i_color = 'lemon') and
        (i_units = 'Gross' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'indian') and
        (i_units = 'Oz' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'lavender') and
        (i_units = 'Ton' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'red' or i_color = 'midnight') and 
        (i_units = 'N/A' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'powder') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'gainsboro') and
        (i_units = 'Carton' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'dodger') and
        (i_units = 'Gram' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
