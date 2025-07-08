WITH RECURSIVE customer_order_totals AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.ct,
        ROW_NUMBER() OVER (ORDER BY c.ct DESC) AS rank
    FROM (
        SELECT 
            c.c_custkey,
            c.c_name,
            COUNT(o.o_orderkey) AS ct
        FROM 
            customer c
        LEFT JOIN 
            orders o ON c.c_custkey = o.o_custkey
        GROUP BY 
            c.c_custkey, c.c_name
    ) c
    WHERE 
        c.ct > 0
)
SELECT 
    p.p_partkey, 
    p.p_name,
    COUNT(l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    r.r_name AS region,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS part_rank
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATE '1997-01-01' 
    AND l.l_shipdate <= DATE '1997-12-31'
    AND EXISTS (
        SELECT 1 
        FROM top_customers tc 
        WHERE tc.c_custkey = ANY (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
        AND tc.rank <= 10
    )
GROUP BY 
    p.p_partkey, p.p_name, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) IS NOT NULL
ORDER BY 
    total_revenue DESC;