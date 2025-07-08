WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, c.c_mktsegment
), TopSegments AS (
    SELECT 
        c.c_mktsegment,
        SUM(revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    WHERE 
        ro.rank <= 5
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    ts.c_mktsegment,
    ts.total_revenue,
    r.r_name AS region_name
FROM 
    TopSegments ts
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_mktsegment = ts.c_mktsegment LIMIT 1)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
ORDER BY 
    ts.total_revenue DESC;