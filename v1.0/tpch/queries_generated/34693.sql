WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.hierarchy_level < 5
),
PartSupplierCount AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
MaxPriceParts AS (
    SELECT p.p_partkey, p.p_name, MAX(p.p_retailprice) AS max_retailprice
    FROM part p
    GROUP BY p.p_partkey, p.p_name
),
OrderLineStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           AVG(l.l_quantity) AS avg_quantity,
           COUNT(DISTINCT l.l_suppkey) AS suppliers_shipped
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)
SELECT r.r_name, 
       COALESCE(SUM(ols.total_revenue), 0) AS total_revenue,
       COALESCE(SUM(ols.avg_quantity), 0) AS avg_quantity,
       COUNT(DISTINCT sh.s_suppkey) AS unique_suppliers_count,
       COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
       AVG(mpp.max_retailprice) AS avg_max_price
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN MaxPriceParts mpp ON ps.ps_partkey = mpp.p_partkey
LEFT JOIN OrderLineStats ols ON ols.o_orderkey = ps.ps_partkey
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY total_revenue DESC;
