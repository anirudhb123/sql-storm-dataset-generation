WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c_acctbal) FROM customer
    )
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > ch.c_acctbal / 2
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_custkey
),
SupplierPartAggregation AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sa.total_available_qty, sa.avg_supply_cost
    FROM supplier s
    LEFT JOIN SupplierPartAggregation sa ON s.s_suppkey = sa.ps_partkey
),
FilteredOrderSummary AS (
    SELECT o.custkey, SUM(os.total_revenue) AS total_order_revenue
    FROM OrderSummary os
    JOIN CustomerHierarchy ch ON os.o_custkey = ch.c_custkey
    GROUP BY o.custkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(fos.total_order_revenue) AS total_revenue_by_nation,
    COALESCE(SUM(sp.total_available_qty), 0) AS total_available_qty,
    AVG(sp.avg_supply_cost) AS average_supply_cost
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierDetails sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN FilteredOrderSummary fos ON s.s_nationkey = fos.custkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING total_revenue_by_nation > 1000000
ORDER BY total_revenue_by_nation DESC;
