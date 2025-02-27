WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_orderkey) AS lineitem_count,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
NationRevenue AS (
    SELECT 
        n.n_name,
        SUM(os.revenue) AS total_revenue
    FROM nation n
    LEFT JOIN OrderStats os ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    GROUP BY n.n_name
)
SELECT 
    p.p_name,
    p.p_color,
    COALESCE(SUM(pr.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    CASE 
        WHEN COALESCE(SUM(pr.total_revenue), 0) >= 10000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN NationRevenue pr ON pr.n_nationkey = s.s_nationkey
WHERE p.p_size BETWEEN 10 AND 20
AND p.p_retailprice IS NOT NULL
GROUP BY p.p_partkey, p.p_name, p.p_color
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY total_revenue DESC
LIMIT 100;
