WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 3000 AND sh.level < 3
),
OrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineitemStatistics AS (
    SELECT l.l_orderkey, COUNT(l.l_linenumber) AS total_lines, AVG(l.l_discount) AS avg_discount
    FROM lineitem l
    GROUP BY l.l_orderkey
),
AggregatePartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY supplier_count DESC
    LIMIT 5
)
SELECT
    p.p_name,
    sh.s_name AS supplying_supplier,
    os.total_order_value AS customer_order_value,
    ls.total_lines,
    ls.avg_discount,
    a.total_supply_cost,
    tn.n_name AS nation_name
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
JOIN LineitemStatistics ls ON ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > 10000))
JOIN OrderSummary os ON os.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_mktsegment = 'BUILDING')
JOIN AggregatePartSupplier a ON ps.ps_partkey = a.ps_partkey
JOIN TopNations tn ON sh.s_nationkey = tn.n_nationkey
WHERE p.p_retailprice BETWEEN 100.00 AND 500.00
  AND (ps.ps_availqty IS NULL OR ps.ps_availqty > 0)
ORDER BY os.total_order_value DESC, a.total_supply_cost ASC
LIMIT 50;
