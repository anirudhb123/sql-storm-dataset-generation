WITH ExpensiveParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice > 100.00
),
SupplierStats AS (
    SELECT s.s_nationkey, SUM(ps.ps_supplycost) AS total_supply_cost,
           AVG(s.s_acctbal) AS avg_account_balance,
           COUNT(s.s_suppkey) AS supplier_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(l.l_quantity) AS total_quantity,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT ns.n_name, 
       COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
       COUNT(DISTINCT ep.p_partkey) AS expensive_part_count,
       MAX(os.total_revenue) AS max_order_revenue,
       MIN(os.total_quantity) AS min_order_quantity
FROM nation ns
LEFT JOIN SupplierStats ss ON ns.n_nationkey = ss.s_nationkey
LEFT JOIN ExpensiveParts ep ON ns.n_nationkey = (
    SELECT n_nationkey 
    FROM supplier s 
    WHERE s.s_suppkey IN (SELECT ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ep.p_partkey)
)
LEFT JOIN OrderSummary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (
    SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey
))
GROUP BY ns.n_name
HAVING COUNT(DISTINCT ep.p_partkey) > 0
ORDER BY total_supply_cost DESC, max_order_revenue DESC;
