WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN SUM(l.l_quantity) IS NULL THEN 'No Orders'
            ELSE COUNT(DISTINCT o.o_orderkey)::text
        END AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    sales.total_sales,
    COALESCE(ROUND(AVG(CASE WHEN s.s_suppkey IS NOT NULL THEN ps.ps_supplycost END), 2), 0) AS avg_supply_cost,
    CASE 
        WHEN COUNT(DISTINCT n.n_nationkey) > 2 THEN 'Multiple Nations'
        ELSE 'Single Nation'
    END AS nation_distribution
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    sales_summary sales ON sales.c_custkey = s.s_nationkey 
WHERE 
    p.p_retailprice BETWEEN 100 AND 500 
    AND (n.r_name IS NULL OR n.r_name LIKE 'Central%')
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice, sales.total_sales
ORDER BY 
    total_sales DESC, p.p_name
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT 
    NULL AS p_partkey,
    'Total Customers Above Threshold' AS p_name,
    NULL AS p_retailprice,
    SUM(total_sales) AS total_sales,
    NULL AS avg_supply_cost,
    NULL AS nation_distribution
FROM 
    top_customers 
WHERE 
    order_count != 'No Orders';
