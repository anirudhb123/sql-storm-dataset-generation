WITH RECURSIVE RegionalSuppliers AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE n.n_regionkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN RegionalSuppliers rs ON n.n_nationkey = rs.n_nationkey
    WHERE n.n_regionkey <> 1
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS unique_customers,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
SupplierPerformance AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(s.s_acctbal) AS avg_account_balance
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT rs.n_name, COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
       SUM(sp.total_avail_qty) AS total_available_quantity,
       AVG(sp.avg_account_balance) AS avg_supply_cost,
       SUM(os.total_revenue) AS total_order_revenue,
       MAX(os.unique_customers) AS max_unique_customers
FROM RegionalSuppliers rs
LEFT JOIN SupplierPerformance sp ON rs.s_suppkey = sp.ps_suppkey
LEFT JOIN OrderSummary os ON rs.n_nationkey = os.o_orderkey
GROUP BY rs.n_name
HAVING COUNT(DISTINCT rs.s_suppkey) > 0 AND SUM(sp.total_avail_qty) > 500
ORDER BY total_order_revenue DESC
LIMIT 10;
