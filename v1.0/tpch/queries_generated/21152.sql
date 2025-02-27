WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_acctbal
    FROM supplier s
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           (CASE WHEN p.p_retailprice IS NULL THEN 0 ELSE p.p_retailprice END) AS adjusted_price
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part))
),
SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           (ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
)
SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(COALESCE(lp.total_supply_cost, 0)) AS total_supply_cost,
       STRING_AGG(DISTINCT p.p_name) AS product_names,
       COUNT(DISTINCT CASE WHEN o.o_orderstatus = 'F' THEN o.o_orderkey END) AS fulfilled_orders,
       MAX(CASE WHEN rp.rank_acctbal = 1 THEN rp.s_name END) AS top_supplier
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN FilteredParts p ON l.l_partkey = p.p_partkey
LEFT JOIN SupplierParts lp ON p.p_partkey = lp.ps_partkey
LEFT JOIN RankedSuppliers rp ON c.c_nationkey = rp.s_nationkey
WHERE n.n_regionkey IS NOT NULL
GROUP BY n.n_name
HAVING SUM(total_supply_cost) > (SELECT AVG(total_supply_cost) FROM SupplierParts WHERE ps_availqty > 0)
   OR COUNT(DISTINCT c.c_custkey) > 100
ORDER BY total_customers DESC NULLS LAST;
