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
        l.l_shipdate >= DATE '2023-01-01' AND 
        l.l_shipdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.total_revenue,
        r.o_orderdate,
        DENSE_RANK() OVER (ORDER BY r.total_revenue DESC) AS revenue_rank
    FROM 
        RankedOrders r
    WHERE 
        r.rn = 1
)
SELECT 
    t.o_orderkey,
    t.total_revenue,
    t.o_orderdate,
    n.n_name AS buyer_nation
FROM 
    TopOrders t
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = t.o_orderkey)
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    t.revenue_rank <= 10
ORDER BY 
    t.total_revenue DESC;
