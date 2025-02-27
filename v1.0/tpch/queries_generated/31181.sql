WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 3000 AND sh.level < 5
),
PartRevenue AS (
    SELECT ps.ps_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2023-01-01'
    GROUP BY ps.ps_partkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS avg_acctbal, SUM(ps.ps_availqty) AS total_available
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_name, p.p_brand, p.p_container, pr.total_revenue, ns.avg_acctbal, ns.supplier_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY pr.total_revenue DESC) as revenue_rank,
    CASE 
        WHEN ns.avg_acctbal IS NULL THEN 'N/A'
        WHEN ns.avg_acctbal < 2000 THEN 'Low'
        WHEN ns.avg_acctbal BETWEEN 2000 AND 5000 THEN 'Medium'
        ELSE 'High'
    END AS balance_category
FROM part p
JOIN PartRevenue pr ON p.p_partkey = pr.ps_partkey
JOIN NationSummary ns ON p.p_partkey % ns.n_nationkey = 0
LEFT JOIN SupplierHierarchy sh ON ns.n_nationkey = sh.s_nationkey
WHERE 
    (sh.level IS NULL OR sh.level < 3)
    AND pr.total_revenue > (SELECT AVG(total_revenue) FROM PartRevenue)
ORDER BY pr.total_revenue DESC, p.p_name;
