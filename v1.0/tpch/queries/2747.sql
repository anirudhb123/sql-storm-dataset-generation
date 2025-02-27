
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
    co.c_custkey,
    co.c_name,
    COALESCE(co.order_count, 0) AS order_count,
    COALESCE(co.total_spent, 0.00) AS total_spent,
    ts.s_name AS top_supplier,
    ts.total_sales
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    TopSuppliers ts ON co.total_spent > 5000 AND ts.sales_rank <= 10
WHERE 
    co.c_custkey IS NOT NULL OR ts.s_suppkey IS NOT NULL
ORDER BY 
    total_spent DESC NULLS LAST;
