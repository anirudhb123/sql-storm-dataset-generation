
WITH RECURSIVE regional_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name
),
top_sales AS (
    SELECT 
        nation_name,
        total_sales
    FROM 
        regional_sales
    WHERE 
        sales_rank <= 3
)
SELECT 
    r.r_name AS region_name,
    ts.nation_name,
    COALESCE(ts.total_sales, 0) AS sales
FROM 
    region r
LEFT JOIN top_sales ts ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = ts.nation_name LIMIT 1)
ORDER BY 
    r.r_name, sales DESC;
