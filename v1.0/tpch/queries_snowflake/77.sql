
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
HighRevenueOrders AS (
    SELECT os.o_orderkey, os.total_revenue, os.order_count
    FROM OrderSummary os
    WHERE os.revenue_rank <= 10
)
SELECT sd.s_name, sd.nation_name, hro.total_revenue, hro.order_count
FROM SupplierDetails sd
LEFT JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN HighRevenueOrders hro ON ps.ps_partkey IN (
    SELECT p.p_partkey
    FROM part p 
    WHERE p.p_retailprice > 100.00
) 
WHERE sd.s_acctbal IS NOT NULL
  AND (sd.s_name LIKE 'A%' OR sd.s_name LIKE '%z')
ORDER BY hro.total_revenue DESC, sd.nation_name;
