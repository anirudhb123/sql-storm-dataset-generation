
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'N%')
    WHERE sh.level < 5
),
OrdersWithHighValue AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
NationDetails AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
CustomerRanked AS (
    SELECT c.c_custkey, c.c_name, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank_within_nation
    FROM customer c
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returned,
    AVG(o.total_value) AS average_order_value,
    d.supplier_count
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN OrdersWithHighValue o ON l.l_orderkey = o.o_orderkey
JOIN NationDetails d ON EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = d.supplier_count)
FULL OUTER JOIN CustomerRanked c ON o.o_custkey = c.c_custkey AND c.rank_within_nation < 5
WHERE p.p_size BETWEEN 1 AND 100
AND p.p_comment IS NOT NULL
GROUP BY p.p_partkey, p.p_name, d.supplier_count
HAVING COUNT(c.c_custkey) > 1
OR EXISTS (SELECT 1 FROM supplier s WHERE s.s_name LIKE 'Supplier%')
ORDER BY total_returned DESC, average_order_value ASC
LIMIT 10;
