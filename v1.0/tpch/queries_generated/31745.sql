WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < 5000
), 
TotalOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01' 
    GROUP BY o.o_custkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size > 10
)
SELECT 
    n.n_name,
    COALESCE(SUM(td.total_spent), 0) AS total_spent,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(ld.l_extendedprice * (1 - ld.l_discount)) OVER (PARTITION BY n.n_nationkey) AS avg_price,
    AVG(ph.depth) AS avg_supplier_depth
FROM nation n
LEFT JOIN TotalOrders td ON td.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN lineitem ld ON ld.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = td.o_custkey)
LEFT OUTER JOIN SupplierHierarchy ph ON ph.s_nationkey = n.n_nationkey
JOIN PartDetails pd ON pd.p_partkey = ld.l_partkey
WHERE n.n_nationkey IS NOT NULL
GROUP BY n.n_name
HAVING SUM(ld.l_quantity) > 100
ORDER BY total_spent DESC, n.n_name
LIMIT 10;
