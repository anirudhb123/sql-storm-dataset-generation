WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
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
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    GROUP BY 
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name, 
        ss.total_parts, 
        ss.total_available_qty, 
        ss.total_supply_cost,
        RANK() OVER (ORDER BY ss.total_supply_cost DESC) AS rank
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_parts > 0
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.total_orders,
    co.total_spent,
    ts.s_name AS top_supplier,
    ts.total_supply_cost AS supplier_cost
FROM 
    CustomerOrders co
LEFT JOIN 
    TopSuppliers ts ON co.total_spent > ts.total_supply_cost
WHERE 
    co.total_orders > 5 AND 
    (co.total_spent / NULLIF(co.total_orders, 0)) > 100
ORDER BY 
    co.total_spent DESC, co.c_name ASC;
