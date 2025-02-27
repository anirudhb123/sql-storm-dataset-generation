WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS tier
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.tier + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.tier < 3
),
qualified_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20 
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_lineitem_value
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
    HAVING o.o_totalprice > 1000
),
suspicious_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'Unknown Balance' 
               WHEN c.c_acctbal < 0 THEN 'Negative Balance'
               ELSE 'Valid Balance'
           END AS balance_status
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
),
region_customer_count AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT rh.*, qp.p_name, qp.p_retailprice, hvo.o_totalprice, 
       sc.c_name, sc.balance_status, rcc.customer_count
FROM supplier_hierarchy rh
JOIN qualified_parts qp ON rh.s_nationkey = qp.p_partkey
JOIN high_value_orders hvo ON qp.p_partkey = hvo.o_orderkey
JOIN suspicious_customers sc ON rh.s_suppkey = sc.c_custkey
JOIN region_customer_count rcc ON rh.s_nationkey = rcc.n_regionkey
WHERE rh.tier <= 2 
AND hvo.total_lineitem_value > 5000
ORDER BY rcc.customer_count DESC, hvo.o_totalprice ASC;
