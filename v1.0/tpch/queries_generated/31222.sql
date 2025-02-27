WITH RECURSIVE SupplierSales AS (
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
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
MaxSales AS (
    SELECT 
        s_suppkey,
        total_sales
    FROM 
        SupplierSales
    WHERE 
        sales_rank = 1
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(co.total_order_value) AS total_value_of_orders,
    (SELECT COUNT(*) FROM MaxSales ms WHERE ms.total_sales > 100000) AS suppliers_above_threshold
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    CustomerOrders co ON s.s_suppkey = co.o_orderkey
WHERE 
    co.o_orderdate >= '2023-01-01' AND 
    (co.total_order_value IS NOT NULL OR co.total_order_value < 1000)
GROUP BY 
    n.n_name
HAVING 
    SUM(co.total_order_value) > 50000
ORDER BY 
    total_value_of_orders DESC
LIMIT 10 OFFSET 5;
