WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, 
           SUM(ps.ps_availqty) AS total_available_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
HighValueOrders AS (
    SELECT os.o_orderkey, os.o_orderdate, os.o_orderstatus, os.total_revenue
    FROM OrderSummary os
    WHERE os.total_revenue > 10000
),
FinalReport AS (
    SELECT ss.nation_name, ss.s_name, 
           COUNT(DISTINCT hvo.o_orderkey) AS high_value_order_count, 
           SUM(ss.total_supply_cost) AS total_supply_cost_per_supplier
    FROM SupplierSummary ss
    LEFT JOIN HighValueOrders hvo ON ss.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        WHERE o.o_orderkey = hvo.o_orderkey
        LIMIT 1
    )
    GROUP BY ss.nation_name, ss.s_name
)
SELECT nation_name, s_name, high_value_order_count, 
       total_supply_cost_per_supplier
FROM FinalReport
ORDER BY total_supply_cost_per_supplier DESC, high_value_order_count DESC;
