WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationDetails AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
)
SELECT n.n_name, nh.level, COALESCE(pc.total_available, 0) AS total_available_parts,
       COALESCE(cd.order_count, 0) AS total_orders, COALESCE(cd.total_spent, 0) AS total_spending
FROM NationDetails n
LEFT JOIN SupplierHierarchy nh ON n.n_nationkey = nh.s_nationkey
LEFT JOIN PartSupplier pc ON pc.p_partkey = (SELECT p.p_partkey FROM part p ORDER BY RANDOM() LIMIT 1)
LEFT JOIN CustomerOrders cd ON cd.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY RANDOM() LIMIT 1)
WHERE nh.level < 5
ORDER BY n.n_name, nh.level DESC;
