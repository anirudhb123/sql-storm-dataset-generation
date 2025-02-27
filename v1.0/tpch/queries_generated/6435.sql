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
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        r.total_revenue
    FROM 
        RankedOrders r 
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.revenue_rank <= 10
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    p.p_name,
    p.p_brand,
    sp.s_name AS supplier_name,
    sp.ps_supplycost,
    tro.total_revenue
FROM 
    part p
JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
JOIN 
    TopRevenueOrders tro ON tro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
ORDER BY 
    total_revenue DESC, p.p_name;
