WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, sp.n_nationkey, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.n_nationkey
    WHERE sp.s_acctbal < sh.s_acctbal
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS suppliers_count,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
        CASE WHEN COUNT(DISTINCT l.l_suppkey) > 1 THEN 'Multiple' ELSE 'Single' END AS supplier_variation
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name AS region_name,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spending
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, r.r_name
)
SELECT 
    cr.c_name,
    cr.region_name,
    COALESCE(sh.level, 0) AS supplier_level,
    od.total_revenue,
    od.suppliers_count,
    od.supplier_variation
FROM CustomerRegions cr
LEFT JOIN SupplierHierarchy sh ON cr.region_name = (SELECT r.r_name FROM region r JOIN nation n ON r.r_regionkey = n.n_regionkey WHERE n.n_nationkey = sh.n_nationkey)
LEFT JOIN OrderDetails od ON cr.c_custkey = od.o_orderkey
WHERE (od.total_revenue IS NOT NULL OR sh.s_supplier_level IS NOT NULL)
AND cr.total_spending > 50000
ORDER BY cr.region_name, od.total_revenue DESC
LIMIT 100;
