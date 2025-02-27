WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS cost_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TotalOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
CustomerRanked AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        to.order_count,
        to.total_spent,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY to.total_spent DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        TotalOrders to ON c.c_custkey = to.o_custkey
)
SELECT 
    rs.nation_name,
    rs.s_name,
    cr.c_name,
    cr.order_count,
    cr.total_spent,
    rs.total_supply_cost
FROM 
    RankedSuppliers rs
JOIN 
    CustomerRanked cr ON rs.cost_rank = 1
WHERE 
    cr.customer_rank <= 3
ORDER BY 
    rs.nation_name, rs.total_supply_cost DESC, cr.total_spent DESC;
