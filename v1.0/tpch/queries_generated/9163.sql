WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        total_available,
        total_cost
    FROM 
        SupplierStats s
    WHERE 
        total_available > 1000 AND total_cost > 50000
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        total_orders,
        total_spent
    FROM 
        CustomerStats c
    WHERE 
        total_orders > 10 AND total_spent > 100000
),
FinalStats AS (
    SELECT 
        hvs.s_name AS supplier_name,
        hvc.c_name AS customer_name,
        hvc.total_orders,
        hvc.total_spent,
        hvs.total_available,
        hvs.total_cost
    FROM 
        HighValueSuppliers hvs
    JOIN 
        HighValueCustomers hvc ON hvs.s_nationkey = hvc.c_nationkey
)
SELECT 
    supplier_name,
    customer_name,
    total_orders,
    total_spent,
    total_available,
    total_cost
FROM 
    FinalStats
ORDER BY 
    total_spent DESC, total_orders DESC;
