WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           o.o_clerk, o.o_orderstatus,
           1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           o.o_clerk, o.o_orderstatus,
           oh.depth + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate < CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND CURRENT_DATE
    AND s.s_acctbal IS NOT NULL
GROUP BY p.p_partkey, p.p_name, p.p_type
HAVING total_sales > 10000
    AND (COUNT(c.c_custkey) IS NULL OR COUNT(c.c_custkey) > 5)
ORDER BY rank_sales, total_sales DESC
LIMIT 100;
