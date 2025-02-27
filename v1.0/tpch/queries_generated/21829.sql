WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= '1995-01-01'
),
SupplierCosts AS (
    SELECT ps.ps_supplycost,
           p.p_name,
           s.s_nationkey,
           CASE WHEN p.p_size IS NULL THEN 'Unknown Size' ELSE CAST(p.p_size AS VARCHAR) END AS part_size
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0 AND s.s_acctbal IS NOT NULL
),
TotalCosts AS (
    SELECT s.s_nationkey,
           SUM(sc.ps_supplycost * (1 - l.l_discount)) AS total_cost,
           AVG(sc.ps_supplycost) AS avg_cost
    FROM lineitem l
    JOIN SupplierCosts sc ON l.l_partkey = sc.p_partkey
    GROUP BY s.s_nationkey
)
SELECT r.r_name,
       COALESCE(tc.total_cost, 0) AS total_supplier_cost,
       CASE WHEN tc.avg_cost IS NULL THEN 'No Data' ELSE CAST(tc.avg_cost AS VARCHAR) END AS avg_supplier_cost,
       (SELECT COUNT(*) FROM RankedOrders ro WHERE ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_discount > 0.1)) AS high_discount_orders,
       CASE 
           WHEN COUNT(DISTINCT n.n_nationkey) > 3 THEN 'Diverse Suppliers'
           ELSE 'Limited Suppliers'
       END AS supplier_diversity
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN TotalCosts tc ON n.n_nationkey = tc.s_nationkey
GROUP BY r.r_name, tc.total_cost, tc.avg_cost
ORDER BY total_supplier_cost DESC, r.r_name ASC
LIMIT 10;
