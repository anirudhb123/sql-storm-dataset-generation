WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_name LIKE 'S%'
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3 AND s.s_name <> sh.s_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey AND o.o_orderstatus NOT IN ('F', 'C')
    GROUP BY c.c_custkey, c.c_name
),
SupplierOrders AS (
    SELECT ps.ps_suppkey, SUM(o.o_totalprice) AS total_supply_profit
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY ps.ps_suppkey
),
RegionSummary AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT c.c_custkey) AS customers_count,
           AVG(s.s_acctbal) AS avg_supplier_balance
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_regionkey, r.r_name
)
SELECT DISTINCT r.r_name, rs.customers_count, rs.avg_supplier_balance, coalesce(SUM(so.total_supply_profit), 0) AS total_profit,
       (SELECT COUNT(*) FROM CustomerOrders CO WHERE CO.total_orders > 2) AS high_volume_customers,
       (SELECT COUNT(*) FROM SupplierHierarchy WHERE level > 1) AS nested_suppliers
FROM RegionSummary rs
LEFT JOIN SupplierOrders so ON rs.n_regionkey = so.ps_suppkey
JOIN region r ON r.r_regionkey = rs.n_regionkey
WHERE r.r_comment IS NOT NULL
GROUP BY r.r_name, rs.customers_count, rs.avg_supplier_balance
HAVING (SUM(so.total_supply_profit) / NULLIF(rs.avg_supplier_balance, 0)) > 1.5
ORDER BY r.r_name DESC NULLS LAST;
