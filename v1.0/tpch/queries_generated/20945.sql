WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_seq
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           (ps.ps_supplycost + (SELECT COALESCE(MAX(ps2.ps_supplycost), 0)
                                FROM partsupp ps2
                                WHERE ps2.ps_partkey = ps.ps_partkey AND ps2.ps_supplycost < ps.ps_supplycost)) * 1.1) AS adjusted_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
), OrderSummary AS (
    SELECT od.o_orderkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(CASE WHEN ps.ps_availqty > 0 THEN od.total_amount ELSE 0 END) AS valid_totals
    FROM OrderDetails od
    LEFT JOIN PartSupplierDetails ps ON od.o_orderkey = ps.p_partkey
    GROUP BY od.o_orderkey
), CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
           MAX(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS full_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT rh.s_name, cs.order_count, os.supplier_count, 
       CASE WHEN cs.full_orders > 0 THEN 'Yes' ELSE 'No' END AS has_full_orders,
       STRING_AGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names,
       SUM(ps.adjusted_cost) AS total_adjusted_cost
FROM SupplierHierarchy rh
JOIN CustomerOrderCount cs ON cs.order_count > 5
JOIN OrderSummary os ON os.supplier_count > 3
JOIN part p ON rh.s_suppkey = p.p_partkey
LEFT JOIN PartSupplierDetails ps ON p.p_partkey = ps.p_partkey
WHERE rh.level IS NOT NULL AND rh.s_name IS NOT NULL
GROUP BY rh.s_name, cs.order_count, os.supplier_count, cs.full_orders
HAVING SUM(ps.adjusted_cost) > 5000
ORDER BY total_adjusted_cost DESC, cs.order_count DESC;
