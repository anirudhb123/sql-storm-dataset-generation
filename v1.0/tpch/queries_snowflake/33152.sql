
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = 1  
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE sh.level < 5
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate > (CAST('1998-10-01' AS DATE) - INTERVAL '1 YEAR')
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_extendedprice) > 100000
)
SELECT 
    r.r_name,
    COALESCE(sh.s_name, 'No Supplier') AS supplier_name,
    COALESCE(hvp.p_name, 'No Part') AS high_value_part,
    COALESCE(ro.o_totalprice, 0) AS o_totalprice,
    COUNT(ro.o_orderkey) AS order_count,
    AVG(ro.o_totalprice) FILTER (WHERE ro.o_totalprice > 500) AS avg_high_value_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN HighValueParts hvp ON sh.s_suppkey = hvp.p_partkey
LEFT JOIN RecentOrders ro ON sh.s_suppkey = ro.o_orderkey
WHERE r.r_name LIKE 'N%'
GROUP BY r.r_name, sh.s_name, hvp.p_name, ro.o_totalprice
ORDER BY r.r_name, supplier_name;
