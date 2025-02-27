WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_nationkey = (SELECT DISTINCT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
lineitem_summary AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS order_count
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY l.l_partkey
),
supplier_availability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT
    p.p_partkey,
    p.p_name,
    p.p_size,
    COALESCE(su.total_available, 0) AS total_available,
    COALESCE(ls.total_revenue, 0) AS total_revenue,
    (COALESCE(ls.total_revenue, 0) / NULLIF(COALESCE(su.total_available, 0), 0)) AS revenue_per_available,
    CASE 
        WHEN COALESCE(su.total_available, 0) = 0 THEN 'No Availability'
        WHEN (COALESCE(ls.total_revenue, 0) / NULLIF(COALESCE(su.total_available, 0), 0)) < 100 THEN 'Low Revenue'
        ELSE 'High Revenue'
    END AS revenue_status
FROM part p
LEFT JOIN supplier_availability su ON p.p_partkey = su.ps_partkey
LEFT JOIN lineitem_summary ls ON p.p_partkey = ls.l_partkey
JOIN nation_hierarchy nh ON nh.n_nationkey = (
    SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey
    )
)
ORDER BY revenue_per_available DESC
LIMIT 10;
