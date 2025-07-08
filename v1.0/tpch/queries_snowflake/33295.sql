WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey
),
TopSpenders AS (
    SELECT c.c_custkey, c.c_name, co.total_spent
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
PartSupplier AS (
    SELECT p.p_partkey, P.p_name, ps.ps_supplycost, ps.ps_availqty,
           SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
)
SELECT th.c_name, th.total_spent, COALESCE(ps.total_available, 0) AS total_available,
       ROW_NUMBER() OVER (PARTITION BY th.c_name ORDER BY th.total_spent DESC) AS rank,
       lh.l_shipmode,
       CASE WHEN lh.l_discount > 0 THEN 'Discounted' ELSE 'Regular Price' END AS pricing_status
FROM TopSpenders th
LEFT JOIN LineItem lh ON th.c_custkey = lh.l_orderkey
LEFT JOIN PartSupplier ps ON lh.l_partkey = ps.p_partkey
WHERE th.total_spent > 1000
ORDER BY th.total_spent DESC, th.c_name ASC;