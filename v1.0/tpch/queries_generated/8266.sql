WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, s.s_suppkey, s.s_name, s.s_accountbal 
    FROM customer c
    JOIN supplier s ON c.c_nationkey = s.s_nationkey
    WHERE c.c_acctbal > 1000
   
    UNION ALL
   
    SELECT ch.c_custkey, ch.c_name, ch.c_acctbal, s.s_suppkey, s.s_name, s.s_acctbal
    FROM CustomerHierarchy ch
    JOIN partsupp ps ON ch.c_custkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 500
   
)
SELECT DISTINCT r.r_name, SUM(o.o_totalprice) AS total_revenue, AVG(l.l_extendedprice) AS avg_lineitem_price
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN CustomerHierarchy ch ON o.o_custkey = ch.c_custkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY r.r_name
ORDER BY total_revenue DESC
LIMIT 10;
