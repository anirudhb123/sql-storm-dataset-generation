WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighSpenderSuppliers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        CustomerOrderStats cs
    JOIN 
        RankedSuppliers rs ON cs.order_count > 5 AND cs.total_spent > 5000 AND rs.rn = 1
)
SELECT 
    hss.c_custkey,
    hss.c_name,
    hss.s_suppkey,
    hss.s_name,
    hss.total_supply_cost
FROM 
    HighSpenderSuppliers hss
WHERE 
    hss.total_supply_cost IS NOT NULL
ORDER BY 
    hss.total_supply_cost DESC;

-- Additional outer join to include customers with no orders
SELECT 
    c.c_custkey, 
    c.c_name, 
    COALESCE(hss.s_suppkey, 0) AS s_suppkey,
    COALESCE(hss.s_name, 'No Supplier') AS s_name,
    COALESCE(hss.total_supply_cost, 0) AS total_supply_cost
FROM 
    customer c
LEFT JOIN 
    HighSpenderSuppliers hss ON c.c_custkey = hss.c_custkey
ORDER BY 
    c.c_custkey;
