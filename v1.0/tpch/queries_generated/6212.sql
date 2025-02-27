WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
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
        ro.order_rank <= 10
)
SELECT 
    c.c_name,
    c.c_acctbal,
    to.total_revenue,
    r.r_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    TopOrders to ON o.o_orderkey = to.o_orderkey
JOIN 
    supplier s ON s.s_nationkey = c.c_nationkey
JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
GROUP BY 
    c.c_name, c.c_acctbal, to.total_revenue, r.r_name
HAVING 
    total_supply_cost > 10000
ORDER BY 
    to.total_revenue DESC;
