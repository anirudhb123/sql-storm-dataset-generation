WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
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
        o.o_orderdate >= '2023-01-01' AND 
        o.o_orderdate < '2023-12-31'
    GROUP BY 
        r.r_name
),
AverageSales AS (
    SELECT 
        region_name,
        AVG(total_sales) OVER () AS avg_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS region_rank
    FROM 
        RegionalSales
)
SELECT 
    r.region_name,
    r.total_sales,
    r.avg_sales,
    CASE 
        WHEN r.total_sales > r.avg_sales THEN 'Above Average'
        WHEN r.total_sales = r.avg_sales THEN 'Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM 
    AverageSales r
WHERE 
    r.region_rank <= 5
ORDER BY 
    r.total_sales DESC;

WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    UNION ALL
    SELECT 
        c.c_custkey,
        c.c_name,
        ch.level + 1
    FROM 
        CustomerHierarchy ch
    JOIN 
        customer c ON c.c_custkey = ch.c_custkey
    WHERE 
        ch.level < 3
)
SELECT 
    ch.c_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    CustomerHierarchy ch
LEFT JOIN 
    orders o ON ch.c_custkey = o.o_custkey
GROUP BY 
    ch.c_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 2;
