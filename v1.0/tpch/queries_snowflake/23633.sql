
WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') 
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
PartSupplierAggregates AS (
    SELECT ps.ps_partkey, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_discount, l.l_returnflag,
           CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END AS refund_amount
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1998-01-01'
)
SELECT 
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(tc.c_name, 'No Customer') AS customer_name,
    rg.r_name AS region_name,
    psa.total_supply_cost,
    fl.refund_amount,
    tc.total_spent,
    COUNT(DISTINCT lc.l_orderkey) AS total_orders,
    MAX(CASE WHEN fl.l_returnflag = 'R' THEN fl.l_quantity END) AS max_returned_quantity
FROM part p
LEFT JOIN PartSupplierAggregates psa ON p.p_partkey = psa.ps_partkey
LEFT JOIN RecursiveSupplier s ON s.rnk = 1 AND s.s_suppkey = 
    (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey LIMIT 1)
LEFT JOIN TopCustomers tc ON tc.c_nationkey = s.s_nationkey
JOIN nation n ON n.n_nationkey = s.s_nationkey
JOIN region rg ON rg.r_regionkey = n.n_regionkey
LEFT JOIN FilteredLineItems fl ON fl.l_partkey = p.p_partkey
LEFT JOIN lineitem lc ON lc.l_orderkey = 
    (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey LIMIT 1)
GROUP BY p.p_name, s.s_name, tc.c_name, rg.r_name, psa.total_supply_cost, fl.refund_amount, tc.total_spent, lc.l_orderkey
HAVING SUM(fl.l_quantity) IS NULL OR COUNT(lc.l_orderkey) > 0
ORDER BY p.p_name;
