WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Top suppliers based on avg account balance
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
    WHERE sh.level < 3  -- Limit recursion depth to 3
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(month, -6, CURRENT_DATE)
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT
    p.p_name,
    p.p_retailprice,
    COALESCE(sum(li.l_extendedprice * (1 - li.l_discount)), 0) AS sales,
    COUNT(DISTINCT oh.o_orderkey) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COUNT(oh.o_orderkey) DESC) AS order_rank
FROM part p
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN RecentOrders oh ON li.l_orderkey = oh.o_orderkey
LEFT JOIN PartSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
WHERE p.p_size >= 10
AND p.p_brand IS NOT NULL
AND (sh.s_nationkey IS NOT NULL OR ps.ps_supplycost < 100)
GROUP BY p.p_partkey, p.p_name, p.p_retailprice
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 5000
ORDER BY sales DESC NULLS LAST, total_orders DESC;
