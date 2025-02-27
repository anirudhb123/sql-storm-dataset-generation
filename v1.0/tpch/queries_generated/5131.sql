WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
), CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
)
SELECT 
    cs.c_name,
    cs.total_spent,
    cs.order_count,
    rs.s_name AS top_supplier,
    rs.total_supply_cost
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    RankedSuppliers rs ON cs.c_custkey = rs.rn AND rs.rn = 1
WHERE 
    cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC;
