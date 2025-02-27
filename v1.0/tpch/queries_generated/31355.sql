WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 50000 AND sh.level < 5
),
SelectedPart AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
AggregatedSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN SelectedPart sp ON l.l_partkey = sp.p_partkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_partkey
),
RankedSales AS (
    SELECT *, RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM AggregatedSales
)
SELECT 
    sh.s_name,
    n.n_name AS nation_name,
    ps.ps_availqty AS available_quantity,
    pr.p_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    CASE
        WHEN rs.sales_rank <= 10 THEN 'Top 10'
        ELSE 'Others'
    END AS sales_category
FROM SupplierHierarchy sh
LEFT JOIN nation n ON sh.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
LEFT JOIN SelectedPart pr ON ps.ps_partkey = pr.p_partkey
LEFT JOIN RankedSales rs ON pr.p_partkey = rs.l_partkey
WHERE ps.ps_availqty > 0
ORDER BY sh.s_name, total_sales DESC;
