WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL
)

, HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           CASE 
               WHEN o.o_totalprice > 1000 THEN 'High Value'
               ELSE 'Regular'
           END AS order_type
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
)

, PartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 
           (ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    WHERE ps.ps_availqty > 
          (SELECT AVG(ps_availqty) FROM partsupp)
)

SELECT
    p.p_name,
    AVG(hvo.o_totalprice) AS average_order_value,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    MAX(ps.total_supply_value) AS max_supply_value,
    STRING_AGG(DISTINCT s.s_name, ', ') FILTER (WHERE s.s_name IS NOT NULL) AS supplier_names
FROM part p
LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN HighValueOrders hvo ON hvo.o_orderkey IN 
    (SELECT l.l_orderkey
     FROM lineitem l
     WHERE l.l_partkey = p.p_partkey AND l.l_returnflag = 'R')
LEFT JOIN SupplierHierarchy s ON ps.ps_suppkey = s.s_suppkey
GROUP BY p.p_name
HAVING COUNT(DISTINCT s.s_nationkey) > 1
ORDER BY average_order_value DESC
LIMIT 10

