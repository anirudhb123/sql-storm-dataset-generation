WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.level < 5 AND s.s_nationkey = sh.s_nationkey 
    WHERE s.s_acctbal IS NULL OR s.s_acctbal > 1000
),
DistinctRegions AS (
    SELECT DISTINCT r.r_name
    FROM region r
    WHERE r.r_comment IS NOT NULL AND LENGTH(r.r_comment) > 20
),
CustomerOrders AS (
    SELECT c.c_custkey, o.o_orderkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c 
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, o.o_orderkey
    HAVING COUNT(o.o_orderkey) > 2
),
PartSuppliers AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_avail, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    GROUP BY ps.ps_partkey
),
OrderDetails AS (
    SELECT o.o_orderkey, 
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
           COUNT(DISTINCT li.l_partkey) AS unique_parts
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE li.l_returnflag = 'N' AND li.l_shipdate IS NOT NULL
    GROUP BY o.o_orderkey
)
SELECT 
    ph.s_suppkey,
    r.r_name,
    AVG(o.total_revenue) AS avg_revenue,
    COALESCE(SUM(ps.total_avail), 0) AS total_availability
FROM SupplierHierarchy ph
LEFT JOIN DistinctRegions r ON r.r_name IS NOT NULL
LEFT JOIN OrderDetails o ON o.o_orderkey IN (SELECT o_orderkey FROM CustomerOrders GROUP BY c_custkey)
LEFT JOIN PartSuppliers ps ON ps.ps_partkey = (
    SELECT p.p_partkey 
    FROM part p 
    WHERE p.p_brand LIKE 'Brand%')
GROUP BY ph.s_suppkey, r.r_name
HAVING AVG(o.total_revenue) > 10000 OR SUM(ps.total_avail) IS NULL
ORDER BY avg_revenue DESC, r.r_name;
