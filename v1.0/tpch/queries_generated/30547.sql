WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.level < 3
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT DISTINCT
    p.p_name,
    p.p_brand,
    SUM(ps.ps_availqty) AS total_available,
    COALESCE(SUM(od.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(od.total_revenue) DESC) AS revenue_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN OrderDetails od ON p.p_partkey = (
    SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate > '2023-01-01')
)
LEFT JOIN TopCustomers c ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey))
WHERE p.p_retailprice > 0
AND p.p_size IN (
    SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost < 50
)
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
HAVING total_available > 100
ORDER BY revenue_rank, total_revenue DESC;
