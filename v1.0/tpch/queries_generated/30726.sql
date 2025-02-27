WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
)

SELECT 
    p.p_name,
    p.p_brand,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY AVG(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank,
    r.r_name AS region_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN customer c ON c.c_custkey = o.o_custkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice)
    FROM part p2
    WHERE p2.p_size <= p.p_size
) AND l.l_shipdate BETWEEN '2023-01-01' AND CURRENT_DATE
GROUP BY p.p_name, p.p_brand, p.p_type, r.r_name
HAVING SUM(CASE WHEN l.l_discount > 0.10 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) > 5000 
    AND COUNT(DISTINCT c.c_custkey) > 5
ORDER BY avg_price DESC
LIMIT 10;
