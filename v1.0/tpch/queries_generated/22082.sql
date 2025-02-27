WITH RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rnk
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
),
SupplierCost AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
ExtremeOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, l.l_quantity,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
),
UncommonNations AS (
    SELECT nation.n_nationkey, nation.n_name, COUNT(DISTINCT supplier.s_suppkey) AS supplier_count
    FROM nation
    LEFT JOIN supplier ON nation.n_nationkey = supplier.s_nationkey
    GROUP BY nation.n_nationkey, nation.n_name
    HAVING COUNT(supplier.s_suppkey) > 5
),
FinalAggregated AS (
    SELECT r.r_regionkey, r.r_name, MAX(c.c_acctbal) AS max_acctbal,
           SUM(s.total_supply_cost) AS total_suppliers_cost,
           COUNT(DISTINCT e.o_orderkey) AS total_orders
    FROM region r
    LEFT JOIN RankedCustomers c ON c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey)
    LEFT JOIN SupplierCost s ON s.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23')
    LEFT JOIN ExtremeOrders e ON e.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_quantity < (SELECT AVG(l2.l_quantity) FROM lineitem l2))
    JOIN UncommonNations n ON r.r_regionkey = (SELECT R.r_regionkey FROM region R WHERE R.r_name = n.name)
    GROUP BY r.r_regionkey, r.r_name
)
SELECT f.r_regionkey, f.r_name, 
       COALESCE(f.max_acctbal, 'No Data') AS max_acctbal,
       CASE 
           WHEN f.total_suppliers_cost IS NULL THEN 'No Suppliers'
           ELSE f.total_suppliers_cost::varchar
       END AS total_suppliers_cost,
       f.total_orders
FROM FinalAggregated f
WHERE f.total_orders >= (SELECT AVG(total_orders) FROM FinalAggregated)
ORDER BY f.max_acctbal DESC NULLS LAST;
