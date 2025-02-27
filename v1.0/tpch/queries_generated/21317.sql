WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        1 AS depth
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 0.00
    UNION ALL
    SELECT 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        sh.depth + 1
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        supplier_hierarchy sh ON ps.ps_partkey = sh.s_suppkey
    WHERE 
        sh.depth < 3
),
customer_order_stats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING' 
    GROUP BY 
        c.c_custkey
),
lineitem_summary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    nh.n_name,
    COUNT(DISTINCT c.c_custkey) AS cust_count,
    AVG(co.total_spent) AS avg_spent,
    SUM(l.total_revenue) AS total_revenue,
    (SELECT COUNT(*) FROM lineitem l2 WHERE l2.l_returnflag = 'R') AS total_returns,
    ROW_NUMBER() OVER (PARTITION BY nh.n_name ORDER BY AVG(co.total_spent) DESC) AS rn
FROM 
    nation nh
LEFT JOIN 
    customer c ON c.c_nationkey = nh.n_nationkey
LEFT JOIN 
    customer_order_stats co ON co.c_custkey = c.c_custkey
LEFT JOIN 
    lineitem_summary l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
WHERE 
    (co.total_orders IS NULL OR co.total_orders < 5)
    AND (c.c_acctbal - COALESCE((SELECT SUM(ps.ps_supplycost) FROM partsupp ps WHERE ps.ps_suppkey = c.c_custkey), 0) > 1000)
GROUP BY 
    nh.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 3
ORDER BY 
    rq.duy, 
    total_revenue DESC, 
    nh.n_name;
