WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND 
        o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS region_name,
    SUM(total_revenue) AS total_revenue,
    cs.total_spent AS customer_spending,
    COUNT(DISTINCT ro.o_orderkey) AS order_count
FROM 
    ranked_orders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    customer_summary cs ON cs.total_spent > 10000
WHERE 
    ro.order_rank = 1
GROUP BY 
    r.r_name, cs.total_spent
ORDER BY 
    total_revenue DESC, customer_spending DESC
LIMIT 10;
