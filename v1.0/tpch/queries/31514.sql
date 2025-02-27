WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
NationSummary AS (
    SELECT n.n_regionkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_regionkey, n.n_name
),
PartSales AS (
    SELECT ps.ps_partkey, COUNT(l.l_orderkey) AS total_sales,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
HighSaleParts AS (
    SELECT p.p_partkey, p.p_name, ps.total_sales, ps.total_revenue,
           ROW_NUMBER() OVER (ORDER BY ps.total_revenue DESC) AS rank
    FROM part p
    JOIN PartSales ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.total_revenue > 1000
)
SELECT nh.n_name AS nation_name, hs.p_name AS top_part_name, hs.total_revenue, sh.level
FROM HighSaleParts hs
JOIN NationSummary nh ON hs.total_sales > nh.supplier_count
JOIN SupplierHierarchy sh ON nh.n_regionkey = sh.s_nationkey
WHERE hs.rank <= 5
ORDER BY hs.total_revenue DESC, sh.level ASC;
