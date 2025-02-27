WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.total_orders
    FROM 
        SupplierSales ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.rank_sales <= 10
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(t.total_sales, 0) AS total_sales,
    COALESCE(t.total_orders, 0) AS total_orders,
    CASE 
        WHEN t.total_sales IS NULL THEN 'No purchases'
        WHEN t.total_sales > 1000 THEN 'High spender'
        ELSE 'Regular customer'
    END AS customer_type
FROM 
    customer c
LEFT JOIN 
    TopSuppliers t ON c.c_custkey IN (
        SELECT DISTINCT o.o_custkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_suppkey IN (SELECT s_suppkey FROM TopSuppliers)
    )
ORDER BY 
    c.c_custkey;
