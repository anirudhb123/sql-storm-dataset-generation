
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000
    UNION ALL
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ch.level + 1
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON c.c_custkey = ch.c_custkey
    WHERE 
        c.c_acctbal <= ch.c_acctbal AND ch.level < 5
),
total_sales AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_custkey
),
customer_sales AS (
    SELECT 
        ch.c_custkey,
        ch.c_name,
        COALESCE(ts.total_spent, 0) AS total_spent
    FROM 
        customer_hierarchy ch
    LEFT JOIN 
        total_sales ts ON ch.c_custkey = ts.o_custkey
),
ranked_customers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS sales_rank
    FROM 
        customer_sales cs
    WHERE 
        cs.total_spent > 1000
)

SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS avg_discount,
    r.r_name AS supplier_region,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    ranked_customers rc ON rc.c_custkey = l.l_orderkey
LEFT JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    l.l_shipdate >= '1997-01-01'
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    p.p_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
