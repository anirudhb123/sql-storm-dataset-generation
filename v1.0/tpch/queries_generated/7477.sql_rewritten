WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.revenue_rank <= 10
)
SELECT 
    p.p_name,
    SUM(ps.ps_availqty) AS total_available_qty,
    AVG(s.s_acctbal) AS average_supplier_balance,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    TopRevenueOrders tro ON tro.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = ps.ps_partkey
    )
JOIN 
    customer c ON tro.o_orderkey = c.c_custkey
GROUP BY 
    p.p_name
ORDER BY 
    total_available_qty DESC;