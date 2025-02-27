WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderstatus, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'O') AND o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
NationRevenue AS (
    SELECT n.n_nationkey, SUM(os.total_revenue) AS nation_revenue
    FROM nation n
    LEFT JOIN OrderSummary os ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = os.o_orderkey) 
    GROUP BY n.n_nationkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING total_cost > 1000
)
SELECT ns.r_name, COUNT(DISTINCT sh.s_suppkey) AS supplier_count, 
       COALESCE(nr.nation_revenue, 0) AS revenue, 
       SUM(CASE WHEN hp.total_cost IS NOT NULL THEN 1 ELSE 0 END) AS high_value_parts_count
FROM region ns
LEFT JOIN nation n ON ns.r_regionkey = n.n_regionkey
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN NationRevenue nr ON n.n_nationkey = nr.n_nationkey
LEFT JOIN HighValueParts hp ON hp.p_partkey IN 
     (SELECT li.l_partkey FROM lineitem li WHERE li.l_orderkey IN 
      (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F'))
GROUP BY ns.r_name
ORDER BY revenue DESC, supplier_count DESC
LIMIT 10;
