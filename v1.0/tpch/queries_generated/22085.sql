WITH CustomerBalance AS (
    SELECT c_custkey, c_name, c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c_mktsegment ORDER BY c_acctbal DESC) AS rank
    FROM customer
),
NationSupplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost,
           AVG(ps.ps_availqty) AS avg_avail_qty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemAggregates AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY l.l_orderkey, l.l_partkey
)
SELECT 
    cb.c_name,
    COALESCE(r.r_name, 'Unknown Region') AS region_name,
    SUM(la.revenue) AS total_revenue,
    MAX(ps.total_supplycost) AS max_supply_cost,
    SUM(CASE WHEN la.unique_suppliers > 10 THEN 1 ELSE 0 END) AS high_supplier_count_orders,
    COUNT(DISTINCT ps.ps_partkey) FILTER (WHERE ps.avg_avail_qty IS NOT NULL) AS parts_with_availability,
    COUNT(DISTINCT cb.custkey) FILTER (WHERE cb.c_acctbal IS NOT NULL OR cb.c_acctbal = 0) AS customers_with_non_negative_balance
FROM CustomerBalance cb
LEFT JOIN orders o ON cb.c_custkey = o.o_custkey
LEFT JOIN LineItemAggregates la ON o.o_orderkey = la.l_orderkey
LEFT JOIN NationSupplier ns ON cb.c_nationkey = ns.n_nationkey
JOIN region r ON ns.n_regionkey = r.r_regionkey
JOIN PartSuppliers ps ON la.l_partkey = ps.ps_partkey
WHERE o.o_orderstatus IN ('O', 'F')
    AND (cb.c_acctbal > 1000 OR cb.c_name LIKE '%Inc%')
GROUP BY cb.c_name, r.r_name
HAVING SUM(la.revenue) > 20000 AND COUNT(DISTINCT cb.custkey) > 5
ORDER BY total_revenue DESC NULLS LAST;
