WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_comment, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'A%')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
)

SELECT 
    r.r_name, 
    COUNT(DISTINCT c.c_custkey) AS cust_count,
    AVG(o.o_totalprice) AS avg_order_price,
    SUM(CASE WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_sales,
    CONCAT('Total Orders: ', COUNT(DISTINCT o.o_orderkey), ' in Region: ', r.r_name) AS order_summary
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = c.c_nationkey
WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2023-12-31'
AND (r.r_name IS NOT NULL OR c.c_phone IS NOT NULL)
GROUP BY r.r_name
HAVING COUNT(c.c_custkey) > 10
ORDER BY 3 DESC, r.r_name NULLS LAST
UNION ALL
SELECT 
    'UNKNOWN' AS r_name, 
    COUNT(DISTINCT c.c_custkey),
    AVG(NULLIF(o.o_totalprice, 0)) AS avg_order_price, 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS discounted_sales,
    '' AS order_summary
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE c.c_comment IS NULL OR c.c_acctbal < 0
GROUP BY c.c_custkey
HAVING COUNT(o.o_orderkey) > 1
ORDER BY 2 DESC;
