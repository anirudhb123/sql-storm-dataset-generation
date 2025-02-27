WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate <= DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), TopRevenue AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        orders o ON ro.o_orderkey = o.o_orderkey
    WHERE 
        ro.revenue_rank <= 10
)
SELECT 
    tr.o_orderkey,
    tr.o_orderdate,
    tr.total_revenue,
    c.c_name AS customer_name,
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    r.r_name AS region_name
FROM 
    TopRevenue tr
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = tr.o_orderkey)
JOIN 
    lineitem li ON li.l_orderkey = tr.o_orderkey
JOIN 
    partsupp ps ON ps.ps_partkey = li.l_partkey AND ps.ps_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = c.c_nationkey)
JOIN 
    part p ON p.p_partkey = li.l_partkey
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON n.n_nationkey = c.c_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
ORDER BY 
    tr.total_revenue DESC;
