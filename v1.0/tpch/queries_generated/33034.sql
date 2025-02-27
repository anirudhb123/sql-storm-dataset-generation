WITH RECURSIVE HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 100000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN HighValueSuppliers hvs ON s.s_suppkey = hvs.s_suppkey + 1
), RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
), SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           COUNT(l.l_linenumber) AS total_lines
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
       AVG(Featuring.total_value) AS avg_order_value, 
       SUM(COALESCE(HP.s_acctbal, 0)) AS total_high_value_supplier_balance
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN RankedOrders o ON n.n_nationkey = (SELECT s_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN LineItemSummary Featuring ON o.o_orderkey = Featuring.l_orderkey
LEFT JOIN HighValueSuppliers HP ON o.o_custkey = HP.s_suppkey
WHERE r.r_name IS NOT NULL AND n.n_comment IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1 AND AVG(Featuring.total_value) > 50000.00
ORDER BY total_high_value_supplier_balance DESC;
