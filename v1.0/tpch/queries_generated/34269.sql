WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS lvl
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.lvl + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availability, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, psi.total_availability, psi.avg_supplycost,
           DENSE_RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    JOIN PartSupplierInfo psi ON p.p_partkey = psi.p_partkey
    WHERE p.p_retailprice IS NOT NULL
)
SELECT th.name, co.order_count, co.total_spent, CASE WHEN co.total_spent IS NULL THEN 'No orders' ELSE 'Has orders' END AS order_status,
       ROW_NUMBER() OVER (PARTITION BY th.price_rank ORDER BY co.total_spent DESC) AS spent_rank
FROM (
    SELECT s.s_name AS name, sh.lvl
    FROM SupplierHierarchy sh
    JOIN supplier s ON sh.s_suppkey = s.s_suppkey
) th
LEFT JOIN CustomerOrders co ON th.name = co.c_custkey
WHERE th.lvl > 0
ORDER BY th.lvl, co.total_spent DESC
LIMIT 100;

