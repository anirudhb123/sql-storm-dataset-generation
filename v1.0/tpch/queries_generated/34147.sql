WITH RECURSIVE regional_sales AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_sales
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) END) > 0
), ranked_sales AS (
    SELECT 
        r.r_name,
        r.total_sales,
        ROW_NUMBER() OVER (ORDER BY r.total_sales DESC) AS sales_rank
    FROM 
        regional_sales r
)

SELECT 
    r.r_name,
    COALESCE(r.total_sales, 0) AS total_sales,
    COALESCE(r.sales_rank, 'N/A') AS sales_rank,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
FROM 
    ranked_sales r
FULL OUTER JOIN 
    supplier s ON r.r_name = (SELECT n.r_name FROM nation n WHERE n.n_nationkey = s.s_nationkey)
WHERE 
    (r.total_sales IS NOT NULL OR s.s_suppkey IS NOT NULL)
GROUP BY 
    r.r_name, r.total_sales, r.sales_rank
ORDER BY 
    total_sales DESC;
