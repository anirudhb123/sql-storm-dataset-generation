WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           COALESCE(NULLIF(o.o_orderstatus, 'F'), 'Z') AS order_status_corrected
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01'
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           (ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part))
)
SELECT r.r_name, ns.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
       SUM(COALESCE(l.l_extendedprice, 0) * (1 - l.l_discount)) AS total_revenue,
       CASE 
           WHEN SUM(l.l_quantity) > 0 THEN SUM(l.l_extendedprice) / NULLIF(SUM(l.l_quantity), 0)
           ELSE 0 
       END AS avg_price_per_quantity,
       STRING_AGG(DISTINCT CONCAT(su.s_name, ': ', su.s_acctbal), '; ') AS supplier_details
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN RankedSuppliers su ON ns.n_nationkey = su.s_suppkey
LEFT JOIN FilteredOrders o ON ns.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE r.r_name LIKE '%E%'
  AND EXISTS (SELECT 1 FROM PartSupplierDetails psd WHERE psd.p_partkey = l.l_partkey AND psd.total_supply_cost > (SELECT AVG(psd.total_supply_cost) FROM PartSupplierDetails))
GROUP BY r.r_name, ns.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_revenue DESC;
