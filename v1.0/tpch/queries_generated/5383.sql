WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        * 
    FROM 
        RankedOrders 
    WHERE 
        revenue_rank <= 10
)
SELECT 
    c.c_name, 
    c.c_acctbal, 
    t.total_revenue, 
    t.o_orderdate 
FROM 
    TopOrders t
JOIN 
    customer c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = t.o_orderkey)
JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = t.o_orderkey)
JOIN 
    supplier s ON s.s_suppkey = ps.ps_suppkey
WHERE 
    s.s_acctbal > 10000
ORDER BY 
    t.total_revenue DESC, c.c_name;
