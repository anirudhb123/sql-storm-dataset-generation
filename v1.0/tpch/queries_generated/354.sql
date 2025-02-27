WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_availability, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemStats AS (
    SELECT 
        l.l_orderkey, 
        COUNT(l.l_linenumber) AS total_line_items, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ss.total_availability, 
        ss.avg_supply_cost
    FROM 
        SupplierStats ss
    ORDER BY 
        ss.total_availability DESC
    LIMIT 10
)
SELECT 
    o.o_orderkey,
    co.total_orders,
    co.total_spent,
    li.total_line_items,
    li.total_revenue,
    ts.s_name AS top_supplier_name,
    ts.avg_supply_cost
FROM 
    CustomerOrderStats co
JOIN 
    LineItemStats li ON co.total_orders = (SELECT COUNT(1) FROM orders WHERE o_orderkey = li.l_orderkey)
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps
                                        JOIN suppliers s ON ps.ps_suppkey = s.s_suppkey
                                        WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = li.l_orderkey)
                                        ORDER BY ps.ps_availqty DESC
                                        LIMIT 1)
WHERE 
    co.total_spent IS NOT NULL
ORDER BY 
    co.total_spent DESC;
