WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IN (SELECT DISTINCT r_regionkey FROM region)

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
total_sales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT 
    np.n_name AS nation_name,
    rp.p_name AS part_name,
    rp.p_retailprice,
    ts.total_revenue,
    CASE 
        WHEN ts.total_revenue IS NULL THEN 'No Sales'
        WHEN ts.total_revenue > 100000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM ranked_parts rp
LEFT JOIN total_sales ts ON rp.p_partkey = ts.l_partkey
JOIN nation_hierarchy np ON np.n_nationkey = (
    SELECT s.s_nationkey 
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    WHERE ps.ps_partkey = rp.p_partkey
    LIMIT 1
)
WHERE rp.rank <= 5
ORDER BY np.n_name, rp.p_retailprice DESC;
