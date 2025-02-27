WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    WHERE 
        l.l_shipdate >= '2023-01-01' 
        AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
), RegionSales AS (
    SELECT 
        n.n_regionkey,
        SUM(rs.sales) AS region_sales
    FROM 
        RankedSales rs
    JOIN 
        supplier s ON rs.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
), TotalSales AS (
    SELECT 
        SUM(sales) AS total_sales
    FROM 
        RankedSales
)
SELECT 
    r.r_name,
    COALESCE(rs.region_sales, 0) AS region_sales,
    ROUND((COALESCE(rs.region_sales, 0) / ts.total_sales) * 100, 2) AS sales_percentage
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_regionkey = rs.n_regionkey
CROSS JOIN 
    TotalSales ts
ORDER BY 
    sales_percentage DESC;
