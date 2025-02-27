WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    
    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer_hierarchy ch
    JOIN orders o ON o.o_custkey = ch.c_custkey
    JOIN lineitem l ON l.l_orderkey = o.o_orderkey
    JOIN partsupp ps ON ps.ps_partkey = l.l_partkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE l.l_discount < (SELECT AVG(l2.l_discount) FROM lineitem l2 WHERE l2.l_orderkey = o.o_orderkey)
)

SELECT 
    n.n_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE 
            WHEN c.c_acctbal IS NULL THEN 0 
            ELSE c.c_acctbal 
        END) AS total_account_balance,
    MAX(COALESCE(n.n_comment, 'No Comment')) AS comment,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    COUNT(DISTINCT l.l_orderkey) FILTER (WHERE l.l_returnflag = 'R') AS return_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY n.n_name ORDER BY r.r_regionkey ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS total_sales
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN lineitem l ON l.l_returnflag IS NULL AND l.l_shipmode <> 'AIR'
LEFT JOIN customer_hierarchy ch ON ch.c_custkey = c.c_custkey
GROUP BY n.n_name, r.r_name
HAVING SUM(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
ORDER BY total_customers DESC, total_account_balance DESC NULLS LAST;
