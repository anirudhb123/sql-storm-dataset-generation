WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.total_quantity,
        r.total_revenue,
        o.o_orderstatus
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.order_rank <= 10
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT to.o_orderkey) AS order_count,
    SUM(to.total_revenue) AS total_revenue,
    AVG(to.total_quantity) AS avg_quantity
FROM 
    TopOrders to
JOIN 
    customer c ON c.c_custkey = to.o_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;
