WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, sh.s_name, depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 100
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(ps.ps_suppkey) > 3
),
EligibleCustomers AS (
    SELECT c.c_custkey, c.c_name, RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    AND c.c_mktsegment IN ('BUILDING', 'HOUSEHOLD')
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(os.total_revenue) AS total_order_revenue,
    COUNT(DISTINCT tp.p_partkey) AS total_parts,
    MAX(sh.depth) AS max_supplier_depth
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
LEFT JOIN OrderSummary os ON o.o_orderkey = os.o_orderkey
LEFT JOIN TopParts tp ON tp.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE n.n_comment IS NOT NULL
GROUP BY n.n_name
HAVING AVG(sh.depth) > 1
ORDER BY total_order_revenue DESC
LIMIT 10;
