WITH RECURSIVE MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS sales_month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY DATE_TRUNC('month', o.o_orderdate)) AS month_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        DATE_TRUNC('month', o.o_orderdate)
    
    UNION ALL

    SELECT 
        DATE_TRUNC('month', o.o_orderdate) AS sales_month,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY DATE_TRUNC('month', o.o_orderdate)) AS month_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND DATE_TRUNC('month', o.o_orderdate) > (SELECT MAX(sales_month) FROM MonthlySales)
    GROUP BY 
        DATE_TRUNC('month', o.o_orderdate)
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(ms.total_sales) AS region_total_sales
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
    JOIN 
        MonthlySales ms ON s.s_suppkey = ms.month_rank -- Assuming month_rank relates to supplier somehow
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    COALESCE(rs.region_total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(rs.region_total_sales, 0) > 100000 THEN 'High Sales'
        WHEN COALESCE(rs.region_total_sales, 0) BETWEEN 50000 AND 100000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    region r
LEFT JOIN 
    RegionSales rs ON r.r_name = rs.r_name
ORDER BY 
    total_sales DESC;
