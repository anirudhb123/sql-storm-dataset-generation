WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON p.p_partkey = ps.ps_partkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_filled_orders,
    STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
AND l.l_shipdate IS NOT NULL
GROUP BY r.r_name, n.n_name
ORDER BY customer_count DESC, total_filled_orders DESC;
