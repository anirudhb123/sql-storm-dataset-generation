WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        rs.part_count, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    ORDER BY 
        rs.total_supply_cost DESC
    LIMIT 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    tc.s_name AS supplier_name,
    co.c_name AS customer_name,
    SUM(co.o_totalprice) AS total_order_value,
    ts.part_count
FROM 
    TopSuppliers ts
JOIN 
    lineitem li ON li.l_suppkey = ts.s_suppkey
JOIN 
    CustomerOrders co ON li.l_orderkey = co.o_orderkey
GROUP BY 
    tc.s_name, co.c_name, ts.part_count
ORDER BY 
    total_order_value DESC, supplier_name ASC;
