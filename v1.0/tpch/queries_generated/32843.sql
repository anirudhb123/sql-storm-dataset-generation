WITH RECURSIVE SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, o.o_orderkey, o.o_orderdate
),
RankedOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_sales,
        RANK() OVER (PARTITION BY s.s_suppkey ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierOrders AS so
    JOIN 
        supplier s ON so.s_suppkey = s.s_suppkey
)
SELECT 
    r.r_name,
    no.n_name,
    SUM(ro.total_sales) AS total_supplier_sales,
    COUNT(DISTINCT ro.o_orderkey) AS number_of_orders,
    MAX(ro.total_sales) AS max_order_value
FROM 
    RankedOrders ro
JOIN 
    supplier s ON ro.s_suppkey = s.s_suppkey
JOIN 
    nation no ON s.s_nationkey = no.n_nationkey
JOIN 
    region r ON no.n_regionkey = r.r_regionkey
WHERE
    ro.sales_rank = 1
GROUP BY 
    r.r_name, no.n_name
HAVING 
    SUM(ro.total_sales) > 1000000
ORDER BY 
    total_supplier_sales DESC
LIMIT 10
OFFSET 5;
