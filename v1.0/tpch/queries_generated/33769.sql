WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)  -- top-level suppliers with above-average account balance
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > sh.s_acctbal * 0.5  -- hierarchical condition for downline suppliers
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
customer_order_counts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        coalesce(coc.total_orders, 0) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY coalesce(coc.total_orders, 0) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_order_counts coc ON c.c_custkey = coc.c_custkey
)
SELECT 
    sh.s_name AS supplier_name,
    os.o_orderkey AS order_key,
    os.total_revenue AS order_revenue,
    tc.c_name AS customer_name,
    tc.total_orders AS customer_order_count
FROM 
    supplier_hierarchy sh
JOIN 
    orders o ON sh.s_suppkey = o.o_custkey
JOIN 
    order_summary os ON o.o_orderkey = os.o_orderkey
JOIN 
    top_customers tc ON o.o_custkey = tc.c_custkey
WHERE 
    os.revenue_rank <= 10 AND  -- top 10 revenue orders
    tc.order_rank <= 5           -- top 5 customers
ORDER BY 
    os.total_revenue DESC, 
    tc.total_orders DESC;
