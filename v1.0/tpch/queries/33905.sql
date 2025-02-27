WITH RECURSIVE CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' 
    UNION ALL
    SELECT 
        co.c_custkey,
        co.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        co.order_level + 1
    FROM 
        CustomerOrders co
    JOIN 
        orders o ON co.o_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
),
TotalSales AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
    GROUP BY 
        s.s_suppkey
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(ts.total_sales) AS region_sales
    FROM 
        TotalSales ts
    JOIN 
        supplier s ON ts.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.region_sales,
    COALESCE(co.cust_order_count, 0) AS customer_order_count,
    ROW_NUMBER() OVER (ORDER BY r.region_sales DESC) AS sales_rank
FROM 
    RegionSales r
LEFT JOIN (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS cust_order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
) co ON r.region_sales > 0
ORDER BY 
    r.region_sales DESC;