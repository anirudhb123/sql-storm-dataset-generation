
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, CAST(c.c_name AS VARCHAR(100)) AS full_name
    FROM customer c
    WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'UNITED STATES')
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, CAST(CONCAT(ch.full_name, ' -> ', c.c_name) AS VARCHAR(100))
    FROM customer c
    JOIN CustomerHierarchy ch ON ch.c_custkey = c.c_nationkey
), OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
), RankedOrders AS (
    SELECT os.o_orderkey, os.o_custkey, os.total_value,
           RANK() OVER (PARTITION BY os.o_custkey ORDER BY os.total_value DESC) AS order_rank
    FROM OrderSummary os
)
SELECT ch.full_name AS Customer_Hierarchy, 
       COUNT(ro.o_orderkey) AS Total_Orders,
       AVG(ro.total_value) AS Average_Order_Value,
       LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS Purchased_Products
FROM CustomerHierarchy ch
LEFT JOIN RankedOrders ro ON ch.c_custkey = ro.o_custkey
LEFT JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
LEFT JOIN partsupp ps ON li.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY ch.full_name
HAVING COUNT(ro.o_orderkey) > 5
ORDER BY AVG(ro.total_value) DESC
LIMIT 10;
