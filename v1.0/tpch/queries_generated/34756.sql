WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name,
           COUNT(n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_totalprice IS NOT NULL AND o.o_orderstatus = 'O'
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS inventory_value
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT rh.r_name, rh.nation_count, rh.total_supplier_balance,
       hh.price_rank, hh.o_totalprice,
       co.c_name, co.order_count, co.avg_order_value,
       ps.p_name, ps.supplier_count, ps.inventory_value
FROM RegionSummary rh
JOIN HighValueOrders hh ON hh.price_rank <= 10
JOIN CustomerOrders co ON co.order_count > 10
JOIN PartSuppliers ps ON ps.inventory_value > 50000
WHERE rh.nation_count IS NOT NULL
AND (rh.total_supplier_balance IS NULL OR rh.total_supplier_balance > 100000)
ORDER BY rh.r_name, hh.o_totalprice DESC;
