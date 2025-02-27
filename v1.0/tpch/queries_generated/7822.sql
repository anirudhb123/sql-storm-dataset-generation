WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
        AND o.o_orderdate < DATE '2023-12-31'
        AND l.l_shipdate >= DATE '2023-01-01'
        AND l.l_shipdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, c.c_name
),
TopRevenueOrders AS (
    SELECT 
        o_orderkey, 
        c_name, 
        total_revenue
    FROM 
        RankedOrders
    WHERE 
        rn = 1
)
SELECT 
    p.p_name,
    s.s_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    COUNT(DISTINCT to.o_orderkey) AS order_count,
    AVG(to.total_revenue) AS avg_order_revenue
FROM 
    partsupp ps
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    TopRevenueOrders to ON l.l_orderkey = to.o_orderkey
GROUP BY 
    p.p_name, s.s_name
ORDER BY 
    total_supply_cost DESC, order_count DESC
LIMIT 10;
