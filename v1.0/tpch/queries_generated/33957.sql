WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal >= (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
sales_summary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey
),
region_sales AS (
    SELECT 
        r.r_regionkey,
        SUM(ss.total_sales) AS region_total_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN sales_summary ss ON s.s_suppkey = ss.o_orderkey
    GROUP BY r.r_regionkey
),
ranked_sales AS (
    SELECT 
        rs.r_regionkey,
        rs.region_total_sales,
        RANK() OVER (ORDER BY rs.region_total_sales DESC) AS sales_rank
    FROM region_sales rs
)
SELECT
    ph.p_partkey,
    ph.p_name,
    ph.p_mfgr,
    ph.p_brand,
    COALESCE(sr.supp_count, 0) AS supplier_count,
    COALESCE(rn.sales_rank, 0) AS top_region_sales_rank
FROM part ph
LEFT JOIN (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supp_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
) sr ON ph.p_partkey = sr.ps_partkey
LEFT JOIN ranked_sales rn ON rn.r_regionkey IN (
    SELECT n.n_nationkey 
    FROM nation n 
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_suppkey IN (SELECT sh.s_suppkey FROM supplier_hierarchy sh)
)
WHERE ph.p_size BETWEEN 10 AND 20
ORDER BY ph.p_partkey;
