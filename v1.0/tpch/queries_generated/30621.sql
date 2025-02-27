WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal > 5000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > 3000 AND ch.level < 3
),
NationSummary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),

AggregatedLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_partkey) AS part_count
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_orderkey
)

SELECT ch.c_name, ns.n_name, ps.p_name,
       al.total_revenue,
       ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY al.total_revenue DESC) AS rank,
       COALESCE(al.part_count, 0) AS part_count,
       COALESCE(ns.supplier_count, 0) AS supplier_count,
       ns.total_acctbal
FROM CustomerHierarchy ch
JOIN customer c ON ch.c_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN NationSummary ns ON n.n_name = ns.n_name
LEFT JOIN (
    SELECT p.p_partkey, p.p_name
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
) ps ON ps.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN AggregatedLineItems al ON ps.ps_partkey = al.l_orderkey
)
LEFT JOIN AggregatedLineItems al ON ch.c_custkey = al.l_orderkey
WHERE ns.total_acctbal IS NOT NULL
ORDER BY ns.n_name, total_revenue DESC
LIMIT 100;
