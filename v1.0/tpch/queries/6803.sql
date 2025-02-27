WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        SUM(so.s_acctbal) AS total_supplier_balance
    FROM 
        supplier so
    JOIN 
        nation n ON so.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_regionkey
    HAVING 
        SUM(so.s_acctbal) > 1000000
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders,
    SUM(ro.revenue) AS total_revenue,
    AVG(ro.customer_count) AS average_customers_per_order
FROM 
    RankedOrders ro
JOIN 
    TopRegions tr ON tr.n_regionkey IN (
        SELECT n.n_regionkey 
        FROM nation n 
        JOIN region r ON n.n_regionkey = r.r_regionkey
    )
JOIN 
    nation n ON ro.o_orderkey IN (
        SELECT o.o_custkey 
        FROM orders o 
        JOIN customer c ON o.o_custkey = c.c_custkey 
        WHERE c.c_nationkey = n.n_nationkey
    )
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;