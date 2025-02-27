WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopNations AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        n.n_name
    ORDER BY 
        customer_count DESC
    LIMIT 5
)
SELECT 
    rn.o_orderkey,
    rn.o_orderdate,
    rn.total_revenue,
    tn.n_name,
    tn.customer_count
FROM 
    RankedOrders rn
JOIN 
    TopNations tn ON rn.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN customer c ON o.o_custkey = c.c_custkey WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = tn.n_name));
