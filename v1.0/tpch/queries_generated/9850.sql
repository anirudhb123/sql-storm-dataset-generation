WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_totalprice
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 1000
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        total_orders > 5
)
SELECT 
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    ts.s_name AS top_supplier,
    cs.total_orders,
    cs.total_spent
FROM 
    RankedOrders r
JOIN 
    TopSuppliers ts ON ts.total_supply_cost > 50000
LEFT JOIN 
    CustomerStats cs ON cs.total_spent > r.o_totalprice
WHERE 
    r.rank_totalprice <= 10
ORDER BY 
    r.o_orderkey, ts.total_supply_cost DESC;
