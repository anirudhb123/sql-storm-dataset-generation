WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderstatus
),

TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 10000
    GROUP BY 
        ps.ps_suppkey, s.s_name
    ORDER BY 
        total_cost DESC
    LIMIT 10
)

SELECT 
    ro.o_orderkey,
    ro.c_name,
    ro.total_revenue,
    ts.s_name AS top_supplier,
    ts.total_cost
FROM 
    RankedOrders ro
JOIN 
    TopSuppliers ts ON ro.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = ts.ps_suppkey LIMIT 1)
WHERE 
    ro.revenue_rank <= 5
ORDER BY 
    ro.total_revenue DESC;
