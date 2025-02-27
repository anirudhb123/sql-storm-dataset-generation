WITH RegionSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
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
    GROUP BY 
        r.r_name
),

CustomerSegmentSales AS (
    SELECT 
        c.c_mktsegment,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_mktsegment
),

SalesRank AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RegionSales
)

SELECT 
    r.region_name,
    COALESCE(c.c_mktsegment, 'Unknown') AS marketing_segment,
    COALESCE(cs.order_count, 0) AS order_count,
    COALESCE(cs.total_revenue, 0.00) AS total_revenue,
    sr.sales_rank
FROM 
    SalesRank sr
LEFT JOIN 
    CustomerSegmentSales cs ON sr.region_name = cs.c_mktsegment
LEFT JOIN 
    region r ON sr.region_name = r.r_name
ORDER BY 
    sr.sales_rank, marketing_segment;

WITH RECURSIVE SalesGrowth AS (
    SELECT 
        o.o_orderdate AS order_date,
        SUM(l.l_extendedprice) AS daily_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice) > 1000
    UNION ALL
    SELECT 
        order_date + INTERVAL '1' DAY,
        SUM(l.l_extendedprice)
    FROM 
        SalesGrowth sg
    JOIN 
        lineitem l ON sg.order_date + INTERVAL '1' DAY = l.l_shipdate
    GROUP BY 
        order_date + INTERVAL '1' DAY
)

SELECT 
    order_date, 
    daily_sales,
    LAG(daily_sales) OVER (ORDER BY order_date) AS previous_day_sales,
    CASE 
        WHEN LAG(daily_sales) OVER (ORDER BY order_date) IS NULL THEN NULL
        ELSE (daily_sales - LAG(daily_sales) OVER (ORDER BY order_date)) / LAG(daily_sales) OVER (ORDER BY order_date) * 100
    END AS sales_growth_percentage
FROM 
    SalesGrowth;
