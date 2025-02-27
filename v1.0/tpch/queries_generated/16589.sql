SELECT l_returnflag, 
       l_linestatus, 
       SUM(l_qty) AS sum_qty, 
       SUM(l_extendedprice) AS sum_extended_price, 
       SUM(l_discount) AS sum_discount
FROM lineitem
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;
