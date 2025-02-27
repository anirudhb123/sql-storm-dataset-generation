WITH RegionalSales AS (
    SELECT
        r.r_name AS region,
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
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY
        r.r_name
),
AvgSales AS (
    SELECT 
        AVG(total_sales) AS avg_total_sales,
        AVG(order_count) AS avg_order_count
    FROM 
        RegionalSales
)
SELECT 
    rs.region,
    rs.total_sales,
    rs.order_count,
    CASE 
        WHEN rs.total_sales > as.avg_total_sales THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison
FROM 
    RegionalSales rs,
    AvgSales as
ORDER BY 
    rs.total_sales DESC;
