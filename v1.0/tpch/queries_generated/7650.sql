WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(co.order_count, 0) AS order_count,
        COALESCE(co.total_spent, 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT t.c_custkey) AS total_customers,
    AVG(t.total_spent) AS avg_spent,
    MAX(t.order_count) AS max_orders,
    JSON_AGG(s.s_name ORDER BY s.total_supply_cost DESC) AS top_suppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
JOIN 
    TopCustomers t ON n.n_nationkey = t.c_nationkey
WHERE 
    rs.rank_within_nation <= 3
GROUP BY 
    r.r_name, n.n_name
HAVING 
    AVG(t.total_spent) > 1000.00
ORDER BY 
    region_name, nation_name;
