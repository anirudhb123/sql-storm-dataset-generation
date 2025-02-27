WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal BETWEEN 500 AND 1000
),
AggregateSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o 
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT n.n_name, 
       COUNT(DISTINCT c.c_custkey) AS unique_customers,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
       AVG(coalesce(ps.ps_supplycost, 0)) AS avg_supply_cost,
       sh.level AS supplier_level
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey 
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
WHERE n.n_name IS NOT NULL 
AND (l.l_discount > 0 OR l.l_tax > 0)
GROUP BY n.n_name, sh.level
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY unique_customers DESC, total_returned_quantity ASC;
