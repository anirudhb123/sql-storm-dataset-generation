WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY s.s_acctbal DESC) as rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = s.s_nationkey)
    UNION ALL
    SELECT sc.s_suppkey, sc.s_name, sc.s_acctbal, p.p_partkey, p.p_name, 
           p.p_retailprice
    FROM supplier_chain sc
    JOIN partsupp ps ON sc.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE s.s_acctbal IS NOT NULL
)
SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS distinct_customers,
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returns,
       AVG(o.o_totalprice) AS avg_order_value,
       COUNT(*) FILTER (WHERE l.l_shipmode IN ('TRUCK', 'SHIP')) AS truck_or_ship_count,
       STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', CAST(p.p_retailprice AS VARCHAR), ')'), ', ') AS product_details
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier_chain sc ON sc.s_suppkey = l.l_suppkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
GROUP BY n.n_name
HAVING COUNT(DISTINCT sc.s_suppkey) > 0
ORDER BY distinct_customers DESC
LIMIT 10;
