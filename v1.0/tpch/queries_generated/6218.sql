WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey
),
TopRevenueOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        c.c_name,
        s.s_name
    FROM 
        RankedOrders r
    JOIN 
        customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = r.o_orderkey)
    JOIN 
        lineitem l ON l.l_orderkey = r.o_orderkey
    JOIN 
        partsupp ps ON ps.ps_partkey = l.l_partkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        r.rn = 1
)
SELECT 
    t.o_orderkey,
    t.total_revenue,
    t.c_name,
    t.s_name,
    COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers
FROM 
    TopRevenueOrders t
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = t.o_orderkey)
GROUP BY 
    t.o_orderkey, t.total_revenue, t.c_name, t.s_name
ORDER BY 
    t.total_revenue DESC
LIMIT 10;
