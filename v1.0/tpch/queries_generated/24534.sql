WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        ranked_orders ro
    WHERE 
        ro.order_rank <= 10
),
suppliers_over_average AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) OVER (PARTITION BY s.s_nationkey) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
    HAVING 
        AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    s.avg_supplycost,
    (SELECT COUNT(DISTINCT c.c_custkey)
     FROM customer c 
     WHERE c.c_nationkey = (SELECT n.n_nationkey 
                             FROM nation n 
                             WHERE n.n_name = 'CANADA')) AS canada_customers
FROM 
    top_orders t
LEFT JOIN 
    suppliers_over_average s ON s.avg_supplycost < t.total_revenue
ORDER BY 
    t.total_revenue DESC NULLS LAST;
