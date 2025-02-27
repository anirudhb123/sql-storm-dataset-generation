WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2022-01-01'
        AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        RANK() OVER (ORDER BY SUM(ro.total_revenue) DESC) AS nation_rank
    FROM 
        nation n
    LEFT JOIN 
        RankedOrders ro ON n.n_nationkey = ro.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        nation_rank <= 3
)
SELECT 
    t.n_name,
    COUNT(r.o_orderkey) AS order_count,
    AVG(r.total_revenue) AS avg_revenue,
    SUM(r.total_revenue) AS total_revenue
FROM 
    TopNations t
LEFT JOIN 
    RankedOrders r ON t.n_nationkey = r.c_nationkey
GROUP BY 
    t.n_name
ORDER BY 
    total_revenue DESC
UNION ALL
SELECT 
    'Overall' AS n_name,
    COUNT(o.o_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    l.l_shipdate >= DATE '2022-01-01' AND l.l_shipdate < DATE '2023-01-01'
HAVING 
    SUM(l.l_discount) IS NOT NULL;
