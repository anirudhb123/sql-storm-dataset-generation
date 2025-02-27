WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 10
),

order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),

extended_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    r.r_name,
    es.n_name,
    es.supplier_count,
    es.total_acctbal,
    SUM(os.total_revenue) FILTER (WHERE os.distinct_parts > 5) AS revenue_high_distinct_parts,
    MAX(os.total_revenue) AS max_order_revenue,
    COUNT(*) OVER (PARTITION BY es.n_name) AS order_count,
    CASE 
        WHEN MIN(s.s_acctbal) IS NULL THEN 'No Suppliers'
        ELSE 'Suppliers Available'
    END AS supplier_availability
FROM region r
JOIN extended_nations es ON r.r_regionkey = es.n_nationkey  -- assuming proper region-key for demonstration
LEFT JOIN order_summary os ON es.n_nationkey = os.o_orderkey  -- assuming matching for orders
LEFT JOIN supplier s ON es.n_nationkey = s.s_nationkey
WHERE es.total_acctbal IS NOT NULL 
GROUP BY r.r_name, es.n_name, es.supplier_count, es.total_acctbal
HAVING COUNT(DISTINCT os.o_orderkey) > 10
ORDER BY revenue_high_distinct_parts DESC NULLS LAST;
