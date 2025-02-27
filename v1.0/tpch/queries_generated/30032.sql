WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), PartMetrics AS (
    SELECT p.p_partkey, 
           SUM(ps.ps_availqty) AS total_availqty,
           AVG(ps.ps_supplycost) AS avg_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS distinct_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
), OrderMetrics AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_name,
    pm.total_availqty,
    pm.avg_supplycost,
    om.total_revenue,
    oh.name AS supplier_name,
    n.n_name AS nation_name
FROM PartMetrics pm
JOIN part p ON pm.p_partkey = p.p_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_nationkey = (
        SELECT s_nationkey 
        FROM supplier 
        WHERE s_suppkey = (
            SELECT ps.ps_suppkey 
            FROM partsupp ps 
            WHERE ps.ps_partkey = p.p_partkey 
            ORDER BY ps.ps_supplycost DESC 
            LIMIT 1
        )
    )
)
LEFT JOIN OrderMetrics om ON om.o_orderkey = (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey = p.p_partkey 
    ORDER BY l.l_extendedprice DESC 
    LIMIT 1
)
JOIN nation n ON sh.s_nationkey = n.n_nationkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) 
    FROM part p2
)
ORDER BY total_revenue DESC
LIMIT 10;
