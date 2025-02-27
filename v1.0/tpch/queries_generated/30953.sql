WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_nationkey = nh.n_regionkey
),
SupplierOrders AS (
    SELECT s.s_suppkey, s.s_name, SUM(o.o_totalprice) AS total_value
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, total_value
    FROM SupplierOrders
    WHERE total_value > (
        SELECT AVG(total_value) * 1.2 FROM SupplierOrders
    )
),
RegionSummary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           AVG(s.s_acctbal) AS avg_account_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT r.r_name, rs.nation_count, rs.avg_account_balance, 
       COALESCE(hvs.total_value, 0) AS total_high_value_order
FROM RegionSummary rs
JOIN region r ON r.r_name = rs.r_name
LEFT JOIN HighValueSuppliers hvs ON r.r_regionkey = hvs.s_suppkey
WHERE (rs.avg_account_balance > 5000 OR rs.nation_count > 5)
ORDER BY r.r_name DESC, total_high_value_order DESC
FETCH FIRST 10 ROWS ONLY;
