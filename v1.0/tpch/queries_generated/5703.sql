WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name,
        r.c_acctbal
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    SUM(l.l_tax) AS total_tax,
    AVG(c.c_acctbal) AS avg_customer_balance
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    TopOrders t ON o.o_orderkey = t.o_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    total_revenue DESC
LIMIT 20;
