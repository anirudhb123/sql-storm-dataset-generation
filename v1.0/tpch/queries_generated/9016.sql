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
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        ps.ps_supplycost,
        p.p_name,
        s.s_name
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    SUM(sp.ps_supplycost) AS total_supply_cost
FROM 
    TopOrders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
JOIN 
    SupplierParts sp ON l.l_partkey = sp.p_partkey
GROUP BY 
    to.o_orderkey, to.o_orderdate
ORDER BY 
    total_supply_cost DESC;
