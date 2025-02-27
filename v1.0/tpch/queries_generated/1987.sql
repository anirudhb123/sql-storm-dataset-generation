WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
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
        ss.total_available_qty,
        ss.avg_supply_cost,
        ss.part_count,
        ROW_NUMBER() OVER (ORDER BY ss.total_available_qty DESC, ss.avg_supply_cost ASC) AS rn
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.part_count > 5
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
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    TOP 10 
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    COALESCE(ol.total_line_value, 0) AS total_order_line_value,
    ts.s_name AS top_supplier_name,
    ts.total_available_qty,
    ts.avg_supply_cost
FROM 
    CustomerOrders cs
LEFT JOIN 
    OrderLineItems ol ON cs.total_orders = (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = cs.c_custkey)
JOIN 
    TopSuppliers ts ON ts.rn <= 10
WHERE 
    cs.total_spent IS NOT NULL
    AND cs.total_orders > 0
ORDER BY 
    cs.total_spent DESC, cs.total_orders ASC;
