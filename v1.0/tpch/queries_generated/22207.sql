WITH RECURSIVE NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
PartReorder AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_availqty) as total_available, 
           MAX(ps.ps_supplycost) as max_supplycost, 
           DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
CustomerOrderAggregation AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
SuspiciousLines AS (
    SELECT l.l_orderkey, l.l_linenumber, l.l_returnflag, 
           CASE WHEN l.l_discount > 0.5 THEN 'Suspicious' ELSE 'Normal' END AS line_status
    FROM lineitem l
    WHERE l.l_shipdate < l.l_commitdate
)
SELECT ns.n_name, pa.p_name, pa.total_available, 
       ca.total_spent, SUM(CASE WHEN sl.line_status = 'Suspicious' THEN 1 ELSE 0 END) AS suspicious_count
FROM NationSummary ns
JOIN PartReorder pa ON ns.supplier_count > pa.rank
JOIN CustomerOrderAggregation ca ON ns.n_nationkey = ca.c_custkey
LEFT JOIN SuspiciousLines sl ON ca.order_count > 5
GROUP BY ns.n_name, pa.p_name, pa.total_available, ca.total_spent
HAVING AVG(pa.total_available) < (SELECT AVG(total_available) FROM PartReorder WHERE max_supplycost > 10.00) 
   AND COUNT(DISTINCT ca.c_custkey) IS NOT NULL
ORDER BY ns.n_name DESC, ca.total_spent DESC;
