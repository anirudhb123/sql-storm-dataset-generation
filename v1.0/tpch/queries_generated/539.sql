WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    WHERE 
        r.revenue_rank <= 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS num_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
    HAVING 
        COUNT(ps.ps_partkey) > 0
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        n.n_regionkey,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_regionkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.total_revenue,
    s.s_suppkey,
    s.num_parts,
    s.total_supply_cost,
    cr.orders_count,
    cr.total_spent
FROM 
    TopOrders t
LEFT JOIN 
    SupplierStats s ON t.total_revenue > s.total_supply_cost
LEFT JOIN 
    CustomerRegions cr ON cr.orders_count > 0
WHERE 
    t.total_revenue IS NOT NULL
ORDER BY 
    t.o_orderdate DESC, 
    t.total_revenue DESC;
