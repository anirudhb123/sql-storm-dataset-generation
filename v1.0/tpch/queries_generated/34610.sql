WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.part_count + COUNT(DISTINCT ps.ps_partkey)
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplyChain sc ON sc.s_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, sc.part_count
),
CustomerRanking AS (
    SELECT c.c_custkey, c.c_name, RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE l.l_extendedprice END) AS total_revenue,
       AVG(s.s_acctbal) AS avg_supplier_balance,
       STRING_AGG(DISTINCT c.c_name, ', ') AS top_customers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN CustomerRanking cr ON s.s_suppkey = cr.c_custkey
WHERE (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY r.r_name
HAVING AVG(s.s_acctbal) > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
ORDER BY total_revenue DESC;
