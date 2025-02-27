WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    ps.p_partkey,
    ps.p_name,
    ps.avg_supply_cost,
    ps.total_avail_qty,
    COALESCE(rs.total_supply_cost, 0) AS supplier_costs,
    co.total_orders,
    co.order_count
FROM 
    CustomerOrders co
JOIN 
    PartStatistics ps ON (ps.avg_supply_cost > 100 AND ps.total_avail_qty > 50)
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND ps.p_partkey = rs.s_suppkey
WHERE 
    co.total_orders > 0
ORDER BY 
    co.total_orders DESC, c.c_name;
