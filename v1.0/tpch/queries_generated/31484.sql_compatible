
WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
nation_sales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(ss.total_sales) AS total_nation_sales
    FROM 
        nation n
    LEFT JOIN 
        sales_summary ss ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = ss.c_custkey)
    GROUP BY 
        n.n_nationkey, n.n_name
),
ranked_nations AS (
    SELECT 
        n.n_name,
        ns.total_nation_sales,
        ROW_NUMBER() OVER (ORDER BY ns.total_nation_sales DESC) AS nation_rank
    FROM 
        nation n
    JOIN 
        nation_sales ns ON n.n_nationkey = ns.n_nationkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS number_of_nations,
    SUM(ns.total_nation_sales) AS aggregate_sales,
    MAX(ns.total_nation_sales) AS max_sales,
    CASE 
        WHEN SUM(ns.total_nation_sales) IS NULL THEN 'No sales' 
        ELSE 'Sales present' 
    END AS sales_status
FROM 
    region r
LEFT JOIN 
    ranked_nations ns ON ns.total_nation_sales IS NOT NULL
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
GROUP BY 
    r.r_name
HAVING 
    MAX(ns.total_nation_sales) > 10000
ORDER BY 
    aggregate_sales DESC;
