WITH RECURSIVE critical_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CASE WHEN s.s_acctbal IS NULL THEN 'No balance' 
                ELSE CASE WHEN s.s_acctbal < 0 THEN 'Negative balance' 
                          ELSE 'Positive balance' END END AS acctbal_status
    FROM supplier s 
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal < 100
    UNION ALL
    SELECT DISTINCT s.s_suppkey, s.s_name, s.s_nationkey,
           CASE WHEN s.s_acctbal IS NULL THEN 'No balance' 
                ELSE CASE WHEN s.s_acctbal < 0 THEN 'Negative balance' 
                          ELSE 'Positive balance' END END AS acctbal_status
    FROM supplier s 
    INNER JOIN critical_suppliers cs ON s.s_nationkey = cs.s_nationkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal < 100
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus
    HAVING COUNT(*) > 5
),
nation_counts AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
    HAVING COUNT(s.s_suppkey) > 0
)
SELECT ns.n_name, ns.supplier_count, cs.acctbal_status, ro.o_orderkey, ro.total_revenue, ro.revenue_rank
FROM nation_counts ns
LEFT JOIN critical_suppliers cs ON ns.supplier_count > 2
LEFT JOIN ranked_orders ro ON cs.s_nationkey = (SELECT n.n_nationkey 
                                                 FROM nation n 
                                                 WHERE n.n_name = 
                                                       CASE 
                                                         WHEN ns.n_supplier_count > 3 THEN 'Argentina' 
                                                         ELSE 'Brazil' 
                                                       END
                                                 LIMIT 1)
WHERE ns.supplier_count BETWEEN 2 AND 10
  AND cs.acctbal_status IS NOT NULL
ORDER BY ns.supplier_count DESC, ro.total_revenue DESC
LIMIT 50;
