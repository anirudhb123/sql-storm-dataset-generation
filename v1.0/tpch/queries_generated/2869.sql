WITH RegionSummary AS (
    SELECT r.r_name AS region_name,
           COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_supplier_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_order_value,
           MAX(o.o_orderdate) AS last_order_date,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierPartPrices AS (
    SELECT ps.ps_partkey,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT rs.region_name, 
       cs.c_custkey, 
       cs.total_order_value, 
       ps.avg_supply_cost, 
       ps.supplier_count,
       CASE 
           WHEN cs.total_order_value IS NULL THEN 'No Orders'
           WHEN cs.total_order_value < 1000 THEN 'Low Value'
           WHEN cs.total_order_value BETWEEN 1000 AND 5000 THEN 'Medium Value'
           ELSE 'High Value' 
       END AS order_value_category
FROM RegionSummary rs
FULL OUTER JOIN CustomerOrderSummary cs ON rs.nation_count > 0 
LEFT JOIN SupplierPartPrices ps ON ps.ps_partkey IN (
    SELECT l.l_partkey 
    FROM lineitem l 
    WHERE l.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o
        WHERE o.o_orderstatus = 'O'
    )
)
WHERE rs.total_supplier_balance IS NOT NULL
ORDER BY rs.region_name, cs.total_order_value DESC;
