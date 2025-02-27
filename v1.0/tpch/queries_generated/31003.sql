WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE 
        s.s_acctbal < sh.s_acctbal
), 
orders_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    ps.ps_availqty,
    SUM(os.total_revenue) AS total_order_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT n.n_nationkey) AS nations_represented,
    CASE 
        WHEN SUM(os.total_revenue) IS NULL THEN 'No Revenue' 
        ELSE CONCAT('Total Revenue: $', ROUND(SUM(os.total_revenue), 2)) 
    END AS revenue_summary,
    sh.level AS supplier_level
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders_summary os ON os.o_orderkey = l.l_orderkey
JOIN 
    customer c ON c.c_custkey = os.o_orderkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    supplier_hierarchy sh ON sh.s_suppkey = ps.ps_suppkey 
WHERE 
    (ps.ps_availqty > 0 AND p.p_retailprice < 50) 
    OR 
    (p.p_type LIKE '%widget%' AND l.l_discount > 0)
GROUP BY 
    p.p_partkey, ps.ps_availqty, sh.level
ORDER BY 
    total_order_revenue DESC
FETCH FIRST 10 ROWS ONLY;
