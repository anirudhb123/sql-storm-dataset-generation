WITH SupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
),
RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_in_nation
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
NestedSubquery AS (
    SELECT c.c_custkey, 
           c.c_name, 
           c.c_acctbal
    FROM customer c
    WHERE c.c_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name LIKE 'A%'
    )
),
FinalReport AS (
    SELECT n.n_name,
           SUM(net_revenue) AS total_revenue,
           COUNT(DISTINCT os.o_orderkey) AS order_count,
           MAX(sc.total_supply_cost) AS max_supply_cost,
           AVG(rn.s_acctbal) AS avg_supplier_balance
    FROM OrderSummary os
    JOIN region r ON r.r_regionkey = (SELECT r_regionkey FROM nation n WHERE n.n_nationkey = (
          SELECT c.c_nationkey FROM NestedSubquery c WHERE c.c_custkey = os.o_orderkey))
    )
    JOIN SupplierCost sc ON os.o_orderkey = sc.ps_partkey
    JOIN RankedSuppliers rn ON sc.ps_partkey = rn.s_suppkey
    JOIN nation n ON rn.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT fr.n_name, 
       fr.total_revenue,
       fr.order_count,
       COALESCE(fr.max_supply_cost, 0) AS adjusted_supply_cost,
       COALESCE(fr.avg_supplier_balance, 0) AS adjusted_average_balance
FROM FinalReport fr
WHERE fr.order_count > 10
ORDER BY fr.total_revenue DESC;
