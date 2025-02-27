WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, ch.c_nationkey, ch.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC)
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_custkey <> ch.c_custkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
           SUM(coalesce(c.c_acctbal, 0)) AS total_acctbal
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name,
           SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT n.n_name, ns.customer_count, ns.total_acctbal,
       SUM(od.total_lineitem_value) AS total_order_value,
       sp.total_available, sp.avg_supply_cost,
       ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY ns.customer_count DESC) AS nation_rank
FROM NationSummary ns
JOIN Nation n ON ns.n_nationkey = n.n_nationkey
LEFT JOIN OrderDetails od ON od.o_orderkey IN (
    SELECT o_orderkey 
    FROM orders 
    WHERE o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
)
LEFT JOIN SupplierPerformance sp ON sp.s_suppkey = (SELECT ps.ps_suppkey
                                                      FROM partsupp ps 
                                                      WHERE ps.ps_partkey = (SELECT p.p_partkey
                                                                             FROM part p WHERE p.p_size > 25 LIMIT 1)
                                                      LIMIT 1)
GROUP BY n.n_name, ns.customer_count, ns.total_acctbal, sp.total_available, sp.avg_supply_cost
ORDER BY ns.total_acctbal DESC, total_order_value DESC;