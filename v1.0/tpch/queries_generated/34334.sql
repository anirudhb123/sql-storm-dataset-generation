WITH RECURSIVE nation_sales AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
ranked_sales AS (
    SELECT 
        n_sales.n_nationkey,
        n_sales.n_name,
        n_sales.total_sales,
        ROW_NUMBER() OVER (ORDER BY n_sales.total_sales DESC) AS sales_rank
    FROM 
        nation_sales n_sales
)
SELECT 
    r.r_name AS region_name,
    COALESCE(rk.n_name, 'No Nation') AS nation_name,
    COALESCE(rk.total_sales, 0) AS total_sales,
    CASE 
        WHEN rk.sales_rank <= 3 THEN 'Top Performer'
        ELSE 'Regular Performer' 
    END AS performance_status
FROM 
    region r
LEFT JOIN 
    (SELECT DISTINCT n.n_nationkey, n.n_name, ns.total_sales, sales_rank
     FROM ranked_sales ns
     JOIN nation n ON ns.n_nationkey = n.n_nationkey) rk 
ON r.r_regionkey = 
    (SELECT n.n_regionkey 
     FROM nation n 
     WHERE n.n_nationkey = rk.n_nationkey LIMIT 1)
ORDER BY 
    region_name, total_sales DESC;
