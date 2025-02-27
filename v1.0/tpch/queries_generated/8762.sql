WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' -- Only completed orders
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cu.c_name AS customer_name,
    cu.total_spent,
    ts.s_name AS top_supplier_name,
    ts.total_supply_cost
FROM 
    CustomerOrders cu
JOIN 
    TopSuppliers ts ON ts.total_supply_cost > 10000 -- Consider suppliers with significant supply cost
ORDER BY 
    cu.total_spent DESC, ts.total_supply_cost DESC
LIMIT 10;
