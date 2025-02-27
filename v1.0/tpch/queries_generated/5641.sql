WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate <= '2023-12-31'
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
        ro.rn = 1
)
SELECT 
    n.n_name AS nation,
    SUM(to.total_revenue) AS total_nation_revenue,
    COUNT(DISTINCT to.o_orderkey) AS total_orders
FROM 
    TopOrders to
JOIN 
    customer c ON to.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_nation_revenue DESC;
