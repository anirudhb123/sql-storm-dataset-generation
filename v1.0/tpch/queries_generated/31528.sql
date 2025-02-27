WITH RECURSIVE part_supplier_hierarchy AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        s.s_name,
        1 AS depth
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 1000

    UNION ALL

    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_suppkey,
        s.s_name,
        depth + 1
    FROM 
        part_supplier_hierarchy h
    JOIN 
        partsupp ps ON h.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    h.p_partkey,
    h.p_name,
    h.s_name,
    COUNT(DISTINCT co.c_custkey) AS unique_customers,
    MAX(co.total_spent) AS max_customer_spending,
    SUM(CASE 
        WHEN co.avg_spent > 500 THEN 1 
        ELSE 0 
    END) AS high_value_customers,
    STRING_AGG(DISTINCT r.r_name) AS regions
FROM 
    part_supplier_hierarchy h
LEFT JOIN 
    customer_order_summary co ON h.ps_suppkey = co.c_custkey
LEFT JOIN 
    supplier s ON h.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    h.depth <= 3
GROUP BY 
    h.p_partkey, h.p_name, h.s_name
HAVING 
    COUNT(DISTINCT co.c_custkey) > 0
ORDER BY 
    max_customer_spending DESC
LIMIT 10;
