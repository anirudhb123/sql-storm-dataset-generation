
WITH SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 20000
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    SUM(COALESCE(ps.total_available, 0)) AS total_part_available,
    AVG(COALESCE(co.total_spent, 0)) AS avg_customer_spending,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
             ELSE 0 END) AS total_returned_revenue
FROM nation n
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN PartStats ps ON ps.p_partkey IN (SELECT ps2.ps_partkey FROM partsupp ps2 WHERE ps2.ps_suppkey = sh.s_suppkey)
LEFT JOIN lineitem l ON l.l_suppkey = sh.s_suppkey
LEFT JOIN CustomerOrders co ON co.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
WHERE n.n_comment IS NOT NULL AND n.n_name LIKE 'A%'
GROUP BY n.n_name
ORDER BY nation_name;
