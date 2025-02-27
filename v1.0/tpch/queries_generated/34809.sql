WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_accountbal > 10000

    UNION ALL

    SELECT ch.c_custkey, ch.c_name, ch.c_nationkey, level + 1
    FROM CustomerHierarchy ch
    JOIN orders o ON ch.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
      AND o.o_orderdate >= DATE '2020-01-01'
)

SELECT 
    p.p_partkey,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    AVG(s.s_acctbal) AS avg_supp_bal,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN customer c ON c.c_nationkey = s.s_nationkey
INNER JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey
WHERE p.p_retailprice IS NOT NULL
  AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
  AND p.p_comment LIKE '%fragile%'
GROUP BY p.p_partkey, p.p_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY revenue DESC, avg_supp_bal ASC;
