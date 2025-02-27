WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s_stats.total_available_qty,
        s_stats.unique_parts_supplied,
        s_stats.avg_supply_cost,
        RANK() OVER (ORDER BY s_stats.total_available_qty DESC) AS rank
    FROM 
        supplier s 
    JOIN 
        SupplierStats s_stats ON s.s_suppkey = s_stats.s_suppkey
    WHERE 
        s_stats.total_available_qty > 100
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    TOP 10 s.s_name AS supplier_name,
    c.c_name AS customer_name,
    co.total_orders,
    co.total_spent,
    co.avg_order_value,
    ts.total_available_qty,
    ts.unique_parts_supplied,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Made'
    END AS order_status
FROM 
    TopSuppliers ts
CROSS JOIN 
    CustomerOrders co
LEFT JOIN 
    nation n ON ts.s_suppkey = n.n_nationkey
WHERE 
    (n.n_name IS NOT NULL OR ts.unique_parts_supplied > 5)
ORDER BY 
    ts.rank, co.total_spent DESC;
