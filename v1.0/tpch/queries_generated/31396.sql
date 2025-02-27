WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 5
),
TotalLineItem AS (
    SELECT l_orderkey,
           SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM lineitem
    WHERE l_shipdate >= '2023-01-01'
    GROUP BY l_orderkey
),
SupplierRevenue AS (
    SELECT s.s_name,
           SUM(pl.total_revenue) AS total_revenue
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN TotalLineItem pl ON pl.l_orderkey = ps.ps_partkey
    GROUP BY s.s_name
),
RankedSuppliers AS (
    SELECT s.s_name,
           sr.total_revenue,
           RANK() OVER (ORDER BY sr.total_revenue DESC) AS rank
    FROM supplier s
    LEFT JOIN SupplierRevenue sr ON s.s_name = sr.s_name
)
SELECT r.r_name, 
       COUNT(DISTINCT ns.n_nationkey) AS nation_count,
       SUM(COALESCE(rs.total_revenue, 0)) AS total_supplier_revenue
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN RankedSuppliers rs ON rs.rank <= 10
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY nation_count DESC, total_supplier_revenue DESC;
