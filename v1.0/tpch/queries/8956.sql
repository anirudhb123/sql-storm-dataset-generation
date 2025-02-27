WITH SupplierLineItem AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS total_orders
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sl.total_sales,
        sl.total_orders,
        RANK() OVER (ORDER BY sl.total_sales DESC) AS sales_rank
    FROM 
        SupplierLineItem sl
    JOIN 
        supplier s ON sl.s_suppkey = s.s_suppkey
)
SELECT 
    ts.sales_rank,
    ts.s_name,
    ts.total_sales,
    ts.total_orders,
    c.c_name AS customer_name,
    c.c_acctbal AS customer_acctbal
FROM 
    TopSuppliers ts
JOIN 
    orders o ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey))
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.sales_rank;