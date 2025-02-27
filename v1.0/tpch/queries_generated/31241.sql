WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON o.o_orderkey > co.o_orderkey
    WHERE co.o_orderdate < o.o_orderdate
),
SupplierPartInfo AS (
    SELECT p.p_name, p.p_retailprice, ps.ps_supplycost, s.s_name, s.s_acctbal
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 500.00
),
AggregatedData AS (
    SELECT COALESCE(n.n_name, 'Unknown') AS nation_name,
           COUNT(DISTINCT co.o_orderkey) AS total_orders,
           SUM(co.o_totalprice) AS total_revenue,
           AVG(sp.ps_supplycost) AS avg_supply_cost
    FROM nation n
    LEFT JOIN CustomerOrders co ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
    LEFT JOIN SupplierPartInfo sp ON sp.p_name LIKE '%widget%'
    GROUP BY n.n_name
),
FinalResult AS (
    SELECT ad.nation_name, ad.total_orders, ad.total_revenue,
           RANK() OVER (ORDER BY ad.total_revenue DESC) AS revenue_rank,
           CASE WHEN ad.total_orders IS NULL THEN 'No Orders' ELSE 'Has Orders' END AS order_status
    FROM AggregatedData ad
)
SELECT fr.nation_name, fr.total_orders, fr.total_revenue, fr.revenue_rank, fr.order_status
FROM FinalResult fr
WHERE fr.order_status = 'Has Orders' 
  AND fr.total_revenue > (
      SELECT AVG(ad.total_revenue) FROM AggregatedData ad
  )
ORDER BY fr.revenue_rank, fr.nation_name;
