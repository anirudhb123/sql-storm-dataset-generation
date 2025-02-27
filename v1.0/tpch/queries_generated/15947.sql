SELECT l.returnflag, 
       l.linestatus, 
       SUM(l.quantity) AS sum_quantity, 
       SUM(l.extendedprice) AS sum_extendedprice, 
       SUM(l.discount) AS sum_discount 
FROM lineitem l 
WHERE l.shipdate >= '1994-01-01' AND l.shipdate < '1995-01-01' 
GROUP BY l.returnflag, l.linestatus 
ORDER BY l.returnflag, l.linestatus;
