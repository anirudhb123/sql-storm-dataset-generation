WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2023-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        s_suppkey,
        s_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SupplierSales
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ts.s_name,
    ts.total_sales,
    co.c_name,
    co.order_count,
    COALESCE(co.total_spent, 0) AS total_spent,
    AVG(ABS(co.total_spent - ts.total_sales)) AS avg_spent_difference
FROM 
    TopSuppliers ts
LEFT JOIN 
    CustomerOrders co ON ts.s_suppkey = co.c_custkey
WHERE 
    ts.sales_rank <= 10
GROUP BY 
    ts.s_name, ts.total_sales, co.c_name, co.order_count
HAVING 
    SUM(co.order_count) > 0 
ORDER BY 
    ts.total_sales DESC, co.total_spent DESC;
