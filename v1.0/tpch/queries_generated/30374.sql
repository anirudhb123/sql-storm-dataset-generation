WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = s.s_nationkey)

    UNION ALL

    SELECT sh.s_suppkey, sh.s_name, sh.s_nationkey, level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > (SELECT AVG(p.p_retailprice) FROM part p2 
                              WHERE p2.p_size = p.p_size)
)

SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(o.o_totalprice) AS total_orders,
    AVG(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS avg_discounted_price,
    COUNT(l.l_orderkey) FILTER (WHERE l.l_returnflag = 'R') AS total_returned_items,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_by_sales
FROM nation n
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
JOIN customer c ON c.c_custkey = o.o_custkey
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
AND (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
GROUP BY n.n_name, sh.level
ORDER BY total_orders DESC;
