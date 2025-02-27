WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
        WHERE s_nationkey IN (
            SELECT n_nationkey
            FROM nation
            WHERE n_name LIKE '%land%'
        )
    )
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(CASE
               WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount)
               ELSE l.l_extendedprice * (1 + l.l_tax)
           END) AS calculated_value
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
        WHERE o2.o_orderdate >= DATEADD(DAY, -30, CURRENT_DATE)
    )
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT r.r_name, rs.nation_count, rs.total_acctbal, COUNT(DISTINCT h.o_orderkey) AS high_value_order_count,
       COALESCE(NULLIF(AVG(h.calculated_value), 0), (SELECT MAX(s.s_acctbal) FROM supplier s)) AS avg_calculated_value
FROM RegionSummary rs
LEFT JOIN HighValueOrders h ON rs.nation_count > 0
LEFT JOIN region r ON rs.r_regionkey = r.r_regionkey
WHERE ABS(rs.nation_count - (SELECT COUNT(*) FROM supplier s WHERE s.s_acctbal > 1000)) < 5
GROUP BY r.r_name, rs.nation_count, rs.total_acctbal
ORDER BY r.r_name, rs.nation_count DESC
LIMIT 10;
