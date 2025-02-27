WITH RECURSIVE SalesCTE AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS rank
    FROM 
        lineitem
    GROUP BY 
        l_orderkey
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(CASE WHEN l.l_shipdate < '2023-01-01' THEN l.l_extendedprice END) AS past_sales,
        SUM(CASE WHEN l.l_shipdate >= '2023-01-01' THEN l.l_extendedprice END) AS current_sales
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
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        r.r_name
),
TopSales AS (
    SELECT 
        sales.l_orderkey,
        sales.total_sales,
        ROW_NUMBER() OVER (ORDER BY sales.total_sales DESC) AS sales_rank
    FROM 
        SalesCTE sales
)
SELECT 
    r.r_name,
    COALESCE(rs.past_sales, 0) AS past_total_sales,
    COALESCE(rs.current_sales, 0) AS current_total_sales,
    (COALESCE(rs.current_sales, 0) - COALESCE(rs.past_sales, 0)) AS sales_difference,
    (SELECT COUNT(*) FROM customer c WHERE c.c_acctbal > 1000) AS high_value_customers,
    (SELECT COUNT(DISTINCT ps.ps_partkey) FROM partsupp ps WHERE ps.ps_availqty > 0) AS available_parts
FROM 
    RegionSales rs
JOIN 
    region r ON r.r_name = rs.r_name
LEFT JOIN 
    TopSales ts ON rs.r_name = ts.l_orderkey
WHERE 
    (rs.past_sales IS NOT NULL OR rs.current_sales IS NOT NULL)
ORDER BY 
    sales_difference DESC;
