WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name
    FROM 
        SupplierSummary s
    WHERE 
        s.rn <= 3
),
LastMonthSales AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATEADD(MONTH, -1, GETDATE())
    GROUP BY 
        l.l_orderkey
)
SELECT 
    c.c_name AS customer_name,
    COALESCE(ord.total_orders, 0) AS total_orders,
    COALESCE(ord.avg_order_value, 0.00) AS avg_order_value,
    COALESCE(sup.s_name, 'Not Available') AS top_supplier_name,
    COALESCE(sales.total_sales, 0.00) AS last_month_sales
FROM 
    customer c
LEFT JOIN 
    CustomerOrders ord ON c.c_custkey = ord.c_custkey
LEFT JOIN 
    TopSuppliers sup ON sup.s_suppkey IN (SELECT ps.s_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 20))
LEFT JOIN 
    LastMonthSales sales ON sales.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
WHERE 
    (c.c_acctbal IS NOT NULL AND c.c_acctbal > 0) 
    OR (c.c_comment LIKE '%VIP%')
ORDER BY 
    total_orders DESC, 
    avg_order_value DESC;
