WITH RECURSIVE HighValueSuppliers AS (
    SELECT ps_suppkey, SUM(ps_supplycost) AS total_supplycost
    FROM partsupp
    GROUP BY ps_suppkey
    HAVING SUM(ps_supplycost) > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_acctbal
    FROM supplier s
    INNER JOIN HighValueSuppliers hvs ON s.s_suppkey = hvs.ps_suppkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) as order_count, 
           SUM(o.o_totalprice) AS total_spending,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
FilteredOrders AS (
    SELECT co.c_custkey, co.c_name, co.order_count, co.total_spending
    FROM CustomerOrders co
    WHERE co.order_count > 5
    AND co.total_spending > (SELECT AVG(total_spending) FROM CustomerOrders)
)
SELECT r.r_name, 
       COALESCE(SUM(CASE WHEN li.l_shipmode = 'AIR' THEN li.l_extendedprice END), 0) AS total_air_shipment,
       COALESCE(SUM(CASE WHEN li.l_shipmode = 'TRUCK' THEN li.l_extendedprice END), 0) AS total_truck_shipment,
       COUNT(DISTINCT f.s_suppkey) AS number_of_suppliers,
       STRING_AGG(DISTINCT f.s_name, ', ') AS supplier_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem li ON li.l_partkey = ps.ps_partkey
LEFT JOIN FilteredOrders f ON s.s_suppkey = f.c_custkey
WHERE n.n_name NOT IN (SELECT DISTINCT n_name FROM nation WHERE n_nationkey % 2 = 0)
AND (s.s_acctbal IS NULL OR s.s_acctbal > 500)
GROUP BY r.r_name
HAVING COUNT(DISTINCT f.c_custkey) > 10
ORDER BY r.r_name DESC
LIMIT 10;
