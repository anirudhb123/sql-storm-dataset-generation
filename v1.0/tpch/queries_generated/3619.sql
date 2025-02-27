WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE()) 
        AND o.o_totalprice > 1000
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        lo.l_shipdate,
        lo.l_discount,
        c.c_name,
        c.c_nationkey
    FROM 
        RankedOrders ro
    JOIN 
        lineitem lo ON lo.l_orderkey = ro.o_orderkey
    JOIN 
        customer c ON c.c_custkey = ro.o_orderkey
    WHERE 
        ro.order_rank <= 5
),
SupplierSales AS (
    SELECT 
        ps.ps_suppkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_sales
    FROM 
        partsupp ps
    JOIN 
        lineitem lo ON lo.l_partkey = ps.ps_partkey
    GROUP BY 
        ps.ps_suppkey
),
AggregateSupplierSales AS (
    SELECT 
        ss.ps_suppkey,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        SupplierSales ss
)
SELECT 
    r.r_name,
    ns.total_sales,
    CASE 
        WHEN ns.total_sales IS NULL THEN 'No Sales'
        ELSE CAST(ns.total_sales AS VARCHAR)
    END AS sales_status,
    COUNT(*) OVER (PARTITION BY r.r_name) AS order_count
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    AggregateSupplierSales ns ON ns.ps_suppkey = n.n_nationkey
WHERE 
    r.r_name LIKE 'A%' OR r.r_name IS NULL
ORDER BY 
    r.r_name, ns.total_sales DESC;
