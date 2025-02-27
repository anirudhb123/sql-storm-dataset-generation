
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey, 
        c.c_acctbal, 
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000

    UNION ALL

    SELECT 
        o.o_custkey, 
        sh.c_name, 
        sh.c_nationkey, 
        sh.c_acctbal, 
        sh.level + 1
    FROM 
        orders o
    JOIN 
        sales_hierarchy sh ON o.o_custkey = sh.c_custkey
)

SELECT 
    n.n_name AS nation_name,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(l.l_shipdate) AS last_ship_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS product_names
FROM 
    lineitem l 
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01'
    AND l.l_shipdate < DATE '1997-12-31'
    AND p.p_size IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) > (
        SELECT AVG(total_sales) FROM (
            SELECT 
                SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
            FROM 
                lineitem l
            JOIN 
                orders o ON l.l_orderkey = o.o_orderkey
            GROUP BY 
                o.o_orderkey
        ) AS avg_sales
    )
ORDER BY 
    total_sales DESC
LIMIT 10;
