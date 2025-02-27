WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_shippriority, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT oh.o_orderkey, oh.o_custkey, oh.o_orderdate, oh.o_shippriority, oh.o_totalprice, oh.level + 1
    FROM orders oh
    JOIN OrderHierarchy oh_parent ON oh.o_custkey = oh_parent.o_custkey AND oh.o_orderdate > oh_parent.o_orderdate
    WHERE oh.o_orderstatus = 'O'
),
SupplierPricing AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 1000
    GROUP BY ps.ps_partkey
),
TotalOrderStats AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey
)
SELECT rh.o_orderkey, rh.o_orderdate, rh.o_shippriority, rh.o_totalprice,
       COALESCE(sp.total_cost, 0) AS supplier_total_cost,
       tos.order_count, tos.avg_order_value
FROM OrderHierarchy rh
LEFT JOIN SupplierPricing sp ON rh.o_orderkey IN (SELECT l_orderkey FROM lineitem WHERE l_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 10))
LEFT JOIN TotalOrderStats tos ON rh.o_custkey = tos.c_custkey
WHERE rh.level = 1 AND rh.o_orderdate >= DATE '2023-01-01'
ORDER BY rh.o_orderdate DESC, rh.o_totalprice DESC;
