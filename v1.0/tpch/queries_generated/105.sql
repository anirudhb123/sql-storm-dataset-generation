WITH SupplierSales AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
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
        ss.s_suppkey, 
        ss.s_name, 
        ss.total_sales 
    FROM 
        SupplierSales ss
    WHERE 
        ss.sales_rank <= 5
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    CASE 
        WHEN o.total_order_value IS NULL THEN 0 
        ELSE o.total_order_value 
    END AS order_value,
    COALESCE(s.total_sales, 0) AS supplier_sales
FROM 
    customer c
LEFT JOIN 
    CustomerOrders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    TopSuppliers s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey IN (
                SELECT o.o_orderkey 
                FROM orders o 
                WHERE o.o_custkey = c.c_custkey
            )
        )
    )
WHERE 
    c.c_acctbal > 500 AND 
    (o.total_order_value IS NULL OR o.total_order_value > 1000)
ORDER BY 
    c.c_custkey;
