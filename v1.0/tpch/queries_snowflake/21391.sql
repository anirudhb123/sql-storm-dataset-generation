
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' AND o.o_orderdate > '1994-01-01'
    GROUP BY o.o_orderkey
),
NationSummary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_name,
    ps.ps_supplycost,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN od.total_price ELSE 0 END) AS total_filled_orders,
    AVG(NC.total_acctbal) AS average_supplier_account_balance,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS price_rank
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
CROSS JOIN NationSummary NC
WHERE 
    (l.l_discount BETWEEN 0.05 AND 0.09 OR l.l_discount IS NULL) 
    AND (p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size IS NOT NULL))
    AND p.p_comment LIKE '%sup%'
GROUP BY p.p_name, p.p_partkey, ps.ps_supplycost, NC.total_acctbal
HAVING COUNT(DISTINCT c.c_custkey) > 5 AND SUM(l.l_extendedprice) IS NOT NULL
ORDER BY price_rank, total_filled_orders DESC
LIMIT 50;
