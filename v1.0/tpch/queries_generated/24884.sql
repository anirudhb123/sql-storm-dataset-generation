WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1 AS level
    FROM 
        SupplierHierarchy sh
    JOIN 
        partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)

SELECT 
    n.n_name,
    r.r_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE NULL END) AS max_returned_price,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_sales,
    AVG(o.o_totalprice) OVER (PARTITION BY n.n_name ORDER BY r.r_name ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS avg_order_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_acctbal), '; ') FILTER (WHERE s.s_acctbal IS NOT NULL) AS supplier_details
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey AND l.l_shipdate < CURRENT_DATE - INTERVAL '30 days'
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
INNER JOIN 
    SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE 
    l.l_shipmode = 'AIR' AND 
    (l.l_tax IS NULL OR l.l_returnflag = 'N')
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    supplier_count DESC, total_sales DESC
HAVING 
    COUNT(ps.ps_availqty) > 5 AND 
    SUM(CASE WHEN l.l_tax IS NOT NULL THEN l.l_tax ELSE 0 END) < 1000
UNION ALL
SELECT 
    'Total' AS n_name,
    'Total' AS r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    MAX(NULL) AS max_returned_price,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_sales,
    AVG(o.o_totalprice) AS avg_order_price,
    NULL AS supplier_details
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipmode IN ('AIR', 'SEA')
AND 
    l.l_receiptdate IS NOT NULL
AND 
    l.l_discount > 0.05
GROUP BY 
    'Total'
ORDER BY 
    supplier_count DESC;
