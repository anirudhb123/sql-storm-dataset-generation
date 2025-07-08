
WITH RegionalSales AS (
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
OrderCounts AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
SalesWithOrderCounts AS (
    SELECT 
        rs.region_name,
        rs.total_sales,
        COALESCE(oc.total_orders, 0) AS total_orders
    FROM 
        RegionalSales rs
    LEFT JOIN 
        OrderCounts oc ON oc.c_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n
            JOIN region r ON n.n_regionkey = r.r_regionkey
            WHERE r.r_name = rs.region_name
            LIMIT 1
        )
)
SELECT 
    sw.region_name,
    sw.total_sales,
    sw.total_orders,
    sw.total_sales / NULLIF(sw.total_orders, 0) AS avg_sales_per_order
FROM 
    SalesWithOrderCounts sw
WHERE 
    sw.total_sales > 10000
ORDER BY 
    avg_sales_per_order DESC
LIMIT 10;
