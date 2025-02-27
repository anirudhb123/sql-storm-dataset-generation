WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_mktsegment
),
TopSegments AS (
    SELECT 
        rank,
        c_mktsegment,
        SUM(revenue) as total_revenue
    FROM 
        RankedOrders
    WHERE 
        rank <= 5
    GROUP BY 
        rank, c_mktsegment
)
SELECT 
    ns.r_name AS region,
    ts.c_mktsegment,
    SUM(ts.total_revenue) AS market_revenue
FROM 
    TopSegments ts
JOIN 
    nation n ON ts.c_mktsegment = n.n_nationkey
JOIN 
    region ns ON n.n_regionkey = ns.r_regionkey
GROUP BY 
    ns.r_name, ts.c_mktsegment
ORDER BY 
    ns.r_name, market_revenue DESC;
