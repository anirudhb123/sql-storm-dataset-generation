
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name, 
    SUM(cs.total_revenue) AS regional_revenue
FROM 
    CustomerSummary cs
JOIN 
    nation n ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    cs.total_revenue > (SELECT AVG(total_revenue) FROM CustomerSummary)
GROUP BY 
    r.r_name
HAVING 
    SUM(cs.total_revenue) > 100000
ORDER BY 
    regional_revenue DESC
LIMIT 10;
