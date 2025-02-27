WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31' 
    GROUP BY 
        o.o_orderkey
), TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.revenue_rank <= 10
), SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem lp ON ps.ps_partkey = lp.l_partkey
    JOIN 
        TopOrders to ON lp.l_orderkey = to.o_orderkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    s.s_name,
    sr.total_revenue
FROM 
    supplier s
JOIN 
    SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
ORDER BY 
    sr.total_revenue DESC
LIMIT 5;
