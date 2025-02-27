WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
TotalLineItem AS (
    SELECT l_partkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    WHERE l_shipdate >= DATE '2023-01-01' AND l_shipdate < DATE '2024-01-01'
    GROUP BY l_partkey
),
PartSupplies AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           (ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
RankedPart AS (
    SELECT p.p_partkey, p.p_name, p.ps_supplycost, p.supply_value,
           RANK() OVER (ORDER BY p.supply_value DESC) AS rank
    FROM PartSupplies p
    JOIN TotalLineItem t ON p.p_partkey = t.l_partkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderpriority, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    AND EXISTS (
        SELECT 1 FROM customer c WHERE c.c_custkey = o.o_custkey AND c.c_acctbal > 1000
    )
)
SELECT rh.s_name AS supplier_name, rh.level, rp.p_name, rp.total_revenue, fo.o_totalprice
FROM SupplierHierarchy rh
LEFT JOIN RankedPart rp ON rp.ps_supplycost < rh.s_acctbal
LEFT JOIN FilteredOrders fo ON fo.o_orderkey = rp.p_partkey
WHERE rh.level < 2
ORDER BY rh.level, rp.total_revenue DESC, fo.o_totalprice DESC;
