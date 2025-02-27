WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        sh.level + 1
    FROM 
        supplier s
    INNER JOIN 
        sales_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE 
        s.s_acctbal < sh.s_acctbal
),
order_summary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2022-01-01' AND 
        l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count, 
        SUM(os.total_revenue) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        order_summary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ch.c_name, 
    ch.order_count, 
    ch.total_spent,
    COALESCE(NULLIF(ch.total_spent, 0), 0) AS spent_non_zero,
    ROW_NUMBER() OVER (PARTITION BY ch.total_spent ORDER BY ch.order_count DESC) AS rank,
    CASE 
        WHEN ch.order_count > 10 THEN 'High Value'
        WHEN ch.order_count BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value,
    n.n_name AS nation_name,
    r.r_name AS region_name
FROM 
    customer_orders ch
LEFT JOIN 
    nation n ON ch.c_custkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    ch.total_spent IS NOT NULL 
    AND ch.order_count > 0
ORDER BY 
    ch.total_spent DESC,
    ch.order_count ASC;
