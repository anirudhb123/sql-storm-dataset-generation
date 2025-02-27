WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey
),

AggregatedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
        MAX(l.l_tax) AS max_tax,
        MIN(l.l_discount) AS min_discount
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
),

CombinedResult AS (
    SELECT 
        ad.p_partkey,
        ad.p_name,
        ad.total_quantity_sold,
        ad.total_orders,
        ad.avg_price_after_discount,
        ad.max_tax,
        ad.min_discount,
        r.r_name AS region_name,
        n.n_name AS nation_name
    FROM AggregatedData ad
    LEFT JOIN supplier s ON ad.p_partkey = s.s_suppkey
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)

SELECT 
    cr.p_partkey,
    cr.p_name,
    cr.total_quantity_sold,
    cr.total_orders,
    ROUND(cr.avg_price_after_discount, 2) AS avg_price,
    cr.max_tax,
    cr.min_discount,
    sh.level AS supplier_hierarchy_level
FROM CombinedResult cr
JOIN SupplierHierarchy sh ON cr.p_partkey = sh.s_suppkey
WHERE (cr.total_orders > 10 OR cr.total_quantity_sold > 100)
  AND cr.max_tax IS NOT NULL
ORDER BY cr.total_orders DESC, cr.total_quantity_sold DESC
LIMIT 100;
