WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, NULL AS parent_suppkey
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal > sh.s_acctbal * 1.1
),
HighValueOrders AS (
    SELECT o_orderkey, o_custkey, SUM(l_extendedprice * (1 - l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o_orderkey, o_custkey
    HAVING SUM(l_extendedprice * (1 - l_discount)) > 50000
),
NationalSuppliers AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) as supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT 
    p.p_name,
    p.p_retailprice,
    ns.n_name AS supplier_nation,
    th.total_order_value,
    ROW_NUMBER() OVER (PARTITION BY ns.n_name ORDER BY th.total_order_value DESC) AS order_rank,
    COALESCE(s.sh_acctbal, 0) AS parent_supplier_acctbal,
    th.total_order_value / NULLIF((SELECT SUM(total_order_value) FROM HighValueOrders), 0) * 100 AS order_percentage
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN NationalSuppliers ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN HighValueOrders th ON th.o_custkey = s.s_nationkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY p.p_name, order_rank DESC;
