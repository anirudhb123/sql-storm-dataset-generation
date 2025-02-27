WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders AS o
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31' 
        AND o.o_orderstatus = 'F' 
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
), 
average_sales AS (
    SELECT 
        c.c_nationkey,
        AVG(total_sales) AS avg_sales
    FROM 
        ranked_orders AS r
    JOIN 
        customer AS c ON r.c_name = c.c_name
    GROUP BY 
        c.c_nationkey
)

SELECT 
    n.n_name, 
    r.total_sales AS country_total_sales, 
    a.avg_sales AS average_sales,
    CASE 
        WHEN r.rn IS NOT NULL THEN 'Top Seller'
        ELSE 'Below Average'
    END AS sales_status
FROM 
    region AS n
LEFT JOIN 
    (SELECT 
         c.c_nationkey,
         SUM(r.total_sales) AS total_sales,
         MAX(rn) AS rn
     FROM 
         ranked_orders AS r
     JOIN 
         customer AS c ON r.c_name = c.c_name
     GROUP BY 
         c.c_nationkey) AS r ON n.r_regionkey = (SELECT n_regionkey FROM nation WHERE n_nationkey = r.c_nationkey)
LEFT JOIN 
    average_sales AS a ON n.r_regionkey = a.c_nationkey
WHERE 
    r.total_sales > (SELECT COALESCE(AVG(total_sales), 0) FROM ranked_orders WHERE rn = 1)
ORDER BY 
    country_total_sales DESC, 
    n.n_name;
