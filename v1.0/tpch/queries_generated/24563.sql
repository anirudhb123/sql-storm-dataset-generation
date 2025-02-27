WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
), 
DiscountSales AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS discounted_sales,
        SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_quantity ELSE 0 END) AS high_discount_qty
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
), 
OutstandingOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (ORDER BY o.o_orderdate DESC) AS order_time_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus <> 'F'
)
SELECT 
    r.region_name,
    rs.order_count,
    rs.total_sales,
    ds.discounted_sales,
    ds.high_discount_qty,
    COALESCE(os.order_time_rank, -1) AS order_time_rank,
    CASE 
        WHEN rs.total_sales IS NULL THEN 'No sales' 
        ELSE 'Sales Available' 
    END AS sales_status
FROM 
    RegionalSales rs
FULL OUTER JOIN 
    DiscountSales ds ON rs.total_sales IS NOT NULL AND ds.discounted_sales > 1000
FULL OUTER JOIN 
    OutstandingOrders os ON rs.total_sales IS NOT NULL AND os.o_orderkey = ds.o_orderkey
WHERE 
    (rs.order_count > 5 OR ds.high_discount_qty > 10)
    AND (rs.total_sales IS NOT NULL OR ds.discounted_sales IS NOT NULL)
ORDER BY 
    r.region_name, 
    total_sales DESC NULLS LAST;
