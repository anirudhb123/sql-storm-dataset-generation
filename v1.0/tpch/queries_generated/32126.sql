WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CAST(s.s_name AS VARCHAR(100)) AS full_name
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CAST(CONCAT(sh.full_name, ' -> ', s.s_name) AS VARCHAR(100))
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE 
        s.s_acctbal > sh.s_suppkey
),

OrderInfo AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        o.o_custkey
),

CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        oi.total_revenue,
        RANK() OVER (ORDER BY oi.total_revenue DESC) AS revenue_rank
    FROM 
        customer c
    JOIN 
        OrderInfo oi ON c.c_custkey = oi.o_custkey
)

SELECT 
    c.c_name AS customer_name,
    cr.revenue_rank,
    COALESCE(sh.full_name, 'No Supplier') AS supplier_hierarchy,
    COUNT(DISTINCT o.o_orderkey) AS orders_placed,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
JOIN 
    CustomerRanking cr ON c.c_custkey = cr.c_custkey
WHERE 
    c.c_acctbal IS NOT NULL
    AND c.c_mktsegment IN ('BUILDING', 'AUTO')
GROUP BY 
    c.c_name, cr.revenue_rank, sh.full_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    cr.revenue_rank ASC, total_spent DESC;
