
WITH RECURSIVE top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice)
                                   FROM orders o2
                                   WHERE o2.o_orderstatus IN ('O', 'F'))
    ORDER BY total_spent DESC
    LIMIT 5
),
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_mfgr, SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_mfgr
    HAVING SUM(ps.ps_availqty) < 100
),
curated_lineitems AS (
    SELECT l.*, ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.01 AND 0.20
    AND l.l_tax IS NOT NULL
)
SELECT DISTINCT n.n_name, SUM(cl.l_extendedprice * (1 - cl.l_discount)) AS total_revenue,
       COUNT(DISTINCT CASE WHEN cl.l_returnflag = 'R' THEN cl.l_orderkey END) AS returns,
       COUNT(DISTINCT CASE WHEN cl.l_returnflag = 'A' THEN cl.l_orderkey END) AS adjustments,
       ROUND(AVG(cl.l_quantity), 2) AS avg_quantity,
       MAX(ps.total_available) AS max_available
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN part_supplier ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN curated_lineitems cl ON cl.l_suppkey = s.s_suppkey
JOIN top_customers tc ON cl.l_orderkey IN (SELECT o.o_orderkey
                                            FROM orders o
                                            WHERE o.o_custkey = tc.c_custkey)
WHERE (tc.total_spent IS NOT NULL OR (tc.total_spent IS NULL AND n.n_name LIKE '%land%'))
GROUP BY n.n_name
HAVING COUNT(cl.l_orderkey) > 5 OR MAX(cl.l_extendedprice) > 500
ORDER BY total_revenue DESC, n.n_name
LIMIT 10 OFFSET 3;
