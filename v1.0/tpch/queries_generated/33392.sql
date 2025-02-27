WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
)
SELECT 
    c.c_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Generated'
    END AS revenue_status
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
AND l.l_shipdate BETWEEN o.o_orderdate AND o.o_orderdate + INTERVAL '30 days'
GROUP BY c.c_name, c.c_nationkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY total_revenue DESC
LIMIT 10;
