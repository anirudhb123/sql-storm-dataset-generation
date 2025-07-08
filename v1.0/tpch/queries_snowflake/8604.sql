WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS monthly_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopMonthlyOrders AS (
    SELECT 
        r.r_name,
        SUM(oo.total_revenue) AS monthly_revenue
    FROM 
        RankedOrders oo
    JOIN 
        customer c ON oo.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        oo.monthly_rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    MAX(t.monthly_revenue) AS max_monthly_revenue,
    AVG(t.monthly_revenue) AS avg_monthly_revenue
FROM 
    TopMonthlyOrders t
JOIN 
    region r ON r.r_name = t.r_name
GROUP BY 
    r.r_name
ORDER BY 
    max_monthly_revenue DESC
LIMIT 10;