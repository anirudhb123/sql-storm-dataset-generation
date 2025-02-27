WITH RECURSIVE TopSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal, 
           ROW_NUMBER() OVER (ORDER BY s_acctbal DESC) AS rank 
    FROM supplier 
    WHERE s_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(DISTINCT o.o_custkey) AS customer_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY o.o_orderkey
),
SupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_available_quantity, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
ProspectiveCustomers AS (
    SELECT DISTINCT c.c_custkey, c.c_name, c.c_mktsegment
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IS NULL OR o.o_orderstatus = 'F'
),
OverdueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, DATEDIFF(CURRENT_DATE, o.o_orderdate) AS overdue_days
    FROM orders o
    WHERE o.o_orderdate < CURRENT_DATE - INTERVAL '30' DAY
)
SELECT r.r_name AS region_name, 
       n.n_name AS nation_name, 
       COUNT(DISTINCT p.p_partkey) AS total_parts,
       SUM(os.total_revenue) AS total_revenue,
       AVG(pd.total_available_quantity) AS avg_avail_qty,
       COALESCE(SUM(td.total_supply_cost), 0) AS total_supply_cost,
       COUNT(DISTINCT pc.c_custkey) AS prospective_customer_count,
       COUNT(DISTINCT oo.o_orderkey) AS overdue_order_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN part p ON n.n_nationkey = p.p_partkey
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o)
LEFT JOIN SupplierDetails pd ON pd.ps_suppkey = (SELECT s.s_suppkey FROM TopSuppliers s WHERE s.rank <= 10)
LEFT JOIN ProspectiveCustomers pc ON pc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_mktsegment = 'BUILDING')
LEFT JOIN OverdueOrders oo ON oo.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderkey = oo.o_orderkey)
WHERE p.p_retailprice > 100.00 AND n.n_name IS NOT NULL
GROUP BY r.r_name, n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
