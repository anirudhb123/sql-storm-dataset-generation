WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CombinedResults AS (
    SELECT 
        r.r_name,
        ro.o_orderkey,
        ro.total_revenue,
        ts.total_cost
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey))
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        TopSuppliers ts ON ts.total_cost > 10000 
    WHERE 
        ro.revenue_rank <= 5
)
SELECT 
    r_name, 
    COUNT(DISTINCT o_orderkey) AS order_count, 
    SUM(total_revenue) AS total_revenue_sum, 
    SUM(total_cost) AS total_cost_sum
FROM 
    CombinedResults
GROUP BY 
    r_name
ORDER BY 
    total_revenue_sum DESC;
