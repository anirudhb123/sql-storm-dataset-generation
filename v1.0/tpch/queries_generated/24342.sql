WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY 
        r.r_name
),
ranked_sales AS (
    SELECT 
        region_name,
        total_sales,
        order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        regional_sales
),
top_regions AS (
    SELECT 
        region_name,
        total_sales,
        order_count
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 5
)

SELECT 
    tr.region_name,
    tr.total_sales,
    tr.order_count,
    COALESCE((SELECT AVG(total_sales) FROM top_regions), 0) AS avg_top_sales,
    CASE 
        WHEN tr.total_sales > (SELECT AVG(total_sales) FROM top_regions) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_performance
FROM 
    top_regions tr
LEFT JOIN 
    customer c ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'France')
WHERE 
    c.custkey IS NULL OR c.c_acctbal > (SELECT MAX(s_acctbal) FROM supplier WHERE s_comment LIKE '%outstanding%')
ORDER BY 
    tr.total_sales DESC;
