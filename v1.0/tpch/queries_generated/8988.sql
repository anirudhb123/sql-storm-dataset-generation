WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation, SUM(ps.ps_availqty) AS total_avail_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity, SUM(l.l_extendedprice) AS total_extended_price
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_partkey
)
SELECT ss.s_name, ss.nation, os.c_name, os.total_order_value, 
       la.total_quantity, la.total_extended_price
FROM SupplierSummary ss
JOIN OrderSummary os ON ss.total_avail_qty > 100
JOIN LineItemAnalysis la ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')))
WHERE os.total_order_value > 10000
ORDER BY ss.total_supply_cost DESC, os.total_order_value DESC;
