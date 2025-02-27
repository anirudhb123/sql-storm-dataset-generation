WITH SupplierRegion AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name, s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, MIN(ps.ps_supplycost) AS min_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
)
SELECT sr.region_name, 
       SUM(od.total_price) AS total_revenue, 
       AVG(sr.s_acctbal) AS avg_supplier_balance, 
       AVG(ps.total_avail_qty) AS avg_available_qty,
       COUNT(DISTINCT sr.s_suppkey) AS supplier_count,
       COUNT(DISTINCT od.o_orderkey) AS order_count
FROM SupplierRegion sr
JOIN OrderDetails od ON sr.s_suppkey = od.o_orderkey
JOIN PartSupplier ps ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = od.o_orderkey)
GROUP BY sr.region_name
ORDER BY total_revenue DESC, avg_supplier_balance DESC;
