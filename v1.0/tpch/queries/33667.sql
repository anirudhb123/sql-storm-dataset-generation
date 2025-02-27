WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        sh.level + 1
    FROM 
        supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
),
aggregated_data AS (
    SELECT 
        p.p_partkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey
),
ranked_parts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY ag.total_revenue DESC) AS revenue_rank,
        COUNT(*) OVER (PARTITION BY p.p_brand) AS brand_count
    FROM 
        part p
    JOIN aggregated_data ag ON p.p_partkey = ag.p_partkey
)
SELECT 
    rp.p_name,
    rp.revenue_rank, 
    rp.brand_count,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    CASE 
        WHEN rp.brand_count > 10 THEN 'High'
        WHEN rp.brand_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS supply_level
FROM 
    ranked_parts rp
LEFT JOIN supplier s ON rp.p_partkey = s.s_suppkey
WHERE 
    rp.revenue_rank <= 10
ORDER BY 
    rp.revenue_rank;
