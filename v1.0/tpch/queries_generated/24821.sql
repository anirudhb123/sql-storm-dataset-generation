WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS depth
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 3
),
OverpricedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_comment, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P') OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey, c.c_name
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal,
           RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT DISTINCT p.p_name, 
       COALESCE(SUM(l.l_extendedprice) FILTER (WHERE l.l_returnflag = 'N'), 0) AS total_sales,
       MIN(sh.s_acctbal) AS min_supplier_acctbal,
       nt.n_name AS nation_name,
       ch.total_orders,
       'Top Part' AS classification
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
JOIN TopNations nt ON nt.n_nationkey = sh.s_nationkey
JOIN CustomerOrders ch ON ch.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderstatus = 'O'))
WHERE p.p_partkey IN (SELECT p1.p_partkey FROM OverpricedParts p1 WHERE p1.price_rank <= 5)
GROUP BY p.p_name, nt.n_name, ch.total_orders
HAVING SUM(l.l_extendedprice) IS NOT NULL OR COUNT(p.p_partkey) > 0
ORDER BY total_sales DESC, nation_name ASC;
