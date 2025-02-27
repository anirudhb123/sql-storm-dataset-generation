WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopCustomerOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.c_name,
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    tco.o_orderkey,
    tco.o_orderdate,
    tco.c_name,
    tco.total_revenue,
    sp.s_suppkey,
    sp.s_name,
    sp.total_cost,
    sp.parts_supplied
FROM 
    TopCustomerOrders tco
JOIN 
    lineitem l ON tco.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    SupplierPerformance sp ON ps.ps_suppkey = sp.s_suppkey
ORDER BY 
    tco.total_revenue DESC, sp.total_cost ASC
LIMIT 100;
