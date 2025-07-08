WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
OrderedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal)
        FROM customer c2
    )
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O' 
      AND EXISTS (SELECT 1 FROM lineitem l WHERE l.l_orderkey = o.o_orderkey AND l.l_discount > 0.1)
)
SELECT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    AVG(l.l_quantity) AS avg_quantity,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    r.r_name
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN region r ON c.c_nationkey = r.r_regionkey
WHERE p.p_retailprice > 0
  AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
  AND EXISTS (SELECT 1 FROM HighValueOrders hvo WHERE hvo.o_orderkey = o.o_orderkey)
GROUP BY p.p_name, r.r_name
ORDER BY revenue DESC
LIMIT 10;
