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
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    c.c_name,
    c.c_acctbal,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS extended_price,
    COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers,
    AVG(s.s_supplycost) AS avg_supply_cost
FROM 
    TopRevenueOrders tro
JOIN 
    orders o ON tro.o_orderkey = o.o_orderkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    o.o_orderkey, o.o_orderdate, c.c_name, c.c_acctbal
ORDER BY 
    total_quantity DESC, o.o_orderdate;
