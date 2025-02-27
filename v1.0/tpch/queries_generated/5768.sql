WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
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
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        hos.total_orders, 
        hos.total_spent, 
        hos.avg_order_value
    FROM 
        CustomerOrderStats hos
    WHERE 
        hos.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderStats)
)
SELECT 
    r.r_name AS region_name,
    nv.n_name AS nation_name,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customers_count,
    SUM(rs.total_supply_cost) AS total_supply_cost_from_top_suppliers
FROM 
    region r
JOIN 
    nation nv ON r.r_regionkey = nv.n_regionkey
JOIN 
    supplier s ON nv.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.supplier_rank <= 10
JOIN 
    HighValueCustomers hvc ON s.s_nationkey = hvc.c_custkey
GROUP BY 
    r.r_name, nv.n_name
ORDER BY 
    r.r_name, nv.n_name;
