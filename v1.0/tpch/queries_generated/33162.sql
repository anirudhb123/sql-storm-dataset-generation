WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
NationRevenues AS (
    SELECT 
        n.n_name,
        SUM(os.total_revenue) AS total_revenue
    FROM ordersummary os
    JOIN customer c ON os.o_orderkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
RegionStats AS (
    SELECT 
        r.r_name,
        AVG(nr.total_revenue) AS avg_revenue,
        COUNT(DISTINCT nr.n_name) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN nationrevenues nr ON n.n_name = nr.n_name
    GROUP BY r.r_name
)
SELECT 
    rh.level,
    r.r_name,
    COALESCE(rs.avg_revenue, 0) AS avg_revenue,
    CASE WHEN rs.nation_count > 2 THEN 'Diverse' ELSE 'Limited' END AS market_diversity
FROM SupplierHierarchy rh
LEFT JOIN RegionStats rs ON rh.s_nationkey = rs.nation_count++;
