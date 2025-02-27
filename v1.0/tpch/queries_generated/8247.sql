WITH RECURSIVE sales_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_summary
),
top_naton_sales AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(ss.total_sales) AS national_sales,
        COUNT(ss.c_custkey) AS customer_count
    FROM 
        ranked_sales ss
    JOIN 
        supplier s ON ss.c_custkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        ss.sales_rank <= 10
    GROUP BY 
        n.n_name
)
SELECT 
    r.r_name AS region_name,
    SUM(t.national_sales) AS total_nation_sales
FROM 
    top_naton_sales t
JOIN 
    region r ON t.nation_name IN (SELECT n_name FROM nation WHERE n_regionkey = r.r_regionkey)
GROUP BY 
    r.r_name
ORDER BY 
    total_nation_sales DESC;
