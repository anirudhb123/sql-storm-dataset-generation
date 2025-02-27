WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(r.total_revenue) AS total_revenue_by_nation
    FROM 
        nation n
    LEFT JOIN 
        RankedOrders r ON n.n_nationkey = c.c_nationkey
    JOIN 
        customer c ON r.c_name = c.c_name
    GROUP BY 
        n.n_name
)
SELECT 
    n.n_name,
    COALESCE(t.total_revenue_by_nation, 0) AS total_revenue,
    CASE 
        WHEN t.total_revenue_by_nation IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS nation_status
FROM 
    nation n
LEFT JOIN 
    TopNations t ON n.n_name = t.n_name
WHERE 
    n.n_nationkey IN (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_acctbal > 500 AND c.c_mktsegment = 'BUILDING')
ORDER BY 
    total_revenue DESC;
