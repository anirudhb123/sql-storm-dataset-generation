WITH RECURSIVE order_hierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
customer_revenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(oh.total_revenue) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        order_hierarchy oh ON c.c_custkey = oh.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
top_customers AS (
    SELECT 
        cr.c_custkey, 
        cr.c_name, 
        cr.total_revenue,
        DENSE_RANK() OVER (ORDER BY cr.total_revenue DESC) AS revenue_rank
    FROM 
        customer_revenue cr
)
SELECT 
    s.s_suppkey,
    s.s_name,
    p.p_name,
    ps.ps_availqty,
    ps.ps_supplycost,
    p.p_retailprice,
    coalesce(tc.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN coalesce(tc.revenue_rank, 0) = 1 THEN 'Top Customer'
        WHEN coalesce(tc.revenue_rank, 0) <= 10 THEN 'High Revenue Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    top_customers tc ON s.s_nationkey = tc.c_custkey
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
    AND ps.ps_availqty IS NOT NULL
ORDER BY 
    total_revenue DESC, s.s_name
FETCH FIRST 100 ROWS ONLY;
