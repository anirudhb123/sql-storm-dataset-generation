WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
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
        SUM(o.o_totalprice) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    rs.s_name AS supplier_name,
    rs.total_supply_cost,
    co.c_name AS customer_name,
    co.total_orders
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey AND rs.supplier_rank <= 3
JOIN 
    CustomerOrders co ON ns.n_nationkey = co.c_nationkey
ORDER BY 
    r.r_name, ns.n_name, rs.total_supply_cost DESC, co.total_orders DESC;
