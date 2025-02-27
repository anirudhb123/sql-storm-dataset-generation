WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1993-01-01' AND o.o_orderdate < '1994-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), SupplierRevenue AS (
    SELECT 
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_name
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(t.total_revenue) AS total_supplier_revenue,
    MAX(ro.revenue) AS max_daily_revenue,
    AVG(ro.revenue) AS avg_daily_revenue
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate = ro.o_orderdate)
JOIN 
    SupplierRevenue t ON t.total_revenue > 10000
WHERE 
    r.r_name LIKE 'N%'
GROUP BY 
    r.r_name
ORDER BY 
    total_supplier_revenue DESC;
