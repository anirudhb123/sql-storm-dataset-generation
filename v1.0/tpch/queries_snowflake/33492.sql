
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_partkey = (
            SELECT l_partkey 
            FROM lineitem 
            WHERE l_suppkey = sh.s_suppkey 
            LIMIT 1
        ) 
        LIMIT 1
    )
    WHERE sh.level < 5
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
), SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, COALESCE(SUM(od.total_revenue), 0) AS total_revenue
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN OrderDetails od ON l.l_orderkey = od.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT rh.r_name, COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
       AVG(sr.total_revenue) AS avg_revenue_per_supplier,
       MAX(sr.total_revenue) AS max_revenue_per_supplier,
       MIN(sr.total_revenue) AS min_revenue_per_supplier
FROM region rh
JOIN nation n ON rh.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
WHERE rh.r_name IS NOT NULL AND sr.total_revenue IS NOT NULL
GROUP BY rh.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 1
ORDER BY avg_revenue_per_supplier DESC, max_revenue_per_supplier ASC;
