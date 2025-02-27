WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier 
    WHERE s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
AvailableParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(li.l_discount) AS total_discount
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate > '2022-01-01'
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING SUM(li.l_discount) > 0.1 * o.o_totalprice
),
DistinctRegions AS (
    SELECT DISTINCT r.r_regionkey
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    WHERE n.n_comment IS NOT NULL
)
SELECT 
    p.p_name,
    COALESCE(ah.total_available, 0) AS available_quantity,
    sh.level AS supplier_level,
    o.o_orderkey,
    o.o_totalprice,
    ho.total_discount,
    r.r_name AS region_name
FROM part p
LEFT JOIN AvailableParts ah ON p.p_partkey = ah.ps_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey
)
FULL OUTER JOIN HighValueOrders ho ON ho.o_orderkey = (
    SELECT MAX(o.o_orderkey)
    FROM orders o
    WHERE o.o_totalprice > 500
)
JOIN DistinctRegions r ON r.r_regionkey = (
    SELECT MAX(n.n_regionkey)
    FROM nation n
    WHERE n.n_nationkey = sh.s_nationkey
)
WHERE (sh.s_acctbal IS NULL OR sh.s_acctbal > 15000)
AND p.p_size BETWEEN 10 AND 50
ORDER BY available_quantity DESC, supplier_level ASC, region_name;
