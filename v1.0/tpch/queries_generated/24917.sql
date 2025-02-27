WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal + sh.s_acctbal, level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
TotalLineItems AS (
    SELECT l.l_orderkey,
           SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM lineitem l
    GROUP BY l.l_orderkey
),
TopNations AS (
    SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name
    HAVING COUNT(DISTINCT c.c_custkey) > (
        SELECT AVG(customer_count)
        FROM (SELECT COUNT(DISTINCT c.c_custkey) AS customer_count
              FROM nation n
              JOIN customer c ON n.n_nationkey = c.c_nationkey
              GROUP BY n.n_name) AS nation_agg
    )
)
SELECT r.r_name, 
       SUM(COALESCE(ll.total_quantity, 0)) AS total_qty_sold,
       SUM(COALESCE(ll.total_revenue, 0)) AS total_revenue_generated,
       MAX(s.s_acctbal) AS max_supplier_balance
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN TotalLineItems ll ON ll.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy s ON s.s_suppkey = (SELECT ps.ps_suppkey
                                                 FROM partsupp ps
                                                 WHERE ps.ps_partkey IN (SELECT p.p_partkey
                                                                         FROM part p
                                                                         WHERE p.p_type LIKE '%metal%')
                                                 ORDER BY ps.ps_supplycost DESC 
                                                 LIMIT 1)
WHERE (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
  AND r.r_name IN (SELECT n_name FROM TopNations WHERE customer_count > 10)
GROUP BY r.r_name
HAVING MAX(s.s_acctbal) IS NOT NULL
ORDER BY total_revenue_generated DESC, total_qty_sold ASC;
