WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 
AvgLineItemPrice AS (
    SELECT l_orderkey, AVG(l_extendedprice * (1 - l_discount)) AS avg_price
    FROM lineitem
    GROUP BY l_orderkey
),
RegionSales AS (
    SELECT n.n_regionkey, r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_regionkey, r.r_name
),
TopSales AS (
    SELECT r.r_name, rs.total_sales,
           RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM RegionSales rs
    JOIN region r ON rs.n_regionkey = r.r_regionkey
)
SELECT sh.s_name, 
       COALESCE(t.total_sales, 0) AS total_sales,
       avg.l_orderkey,
       avg.avg_price,
       CASE 
           WHEN avg.avg_price IS NULL THEN 'No Sales'
           ELSE 'Sales Exist'
       END AS sales_status
FROM SupplierHierarchy sh
LEFT JOIN TopSales t ON sh.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey IN (SELECT DISTINCT r_regionkey FROM region WHERE r_name LIKE 'N%'))
LEFT JOIN AvgLineItemPrice avg ON avg.l_orderkey = (SELECT MIN(l_orderkey) FROM lineitem)
WHERE sh.level = 0 OR sh.level IS NULL
ORDER BY sh.s_name, t.total_sales DESC;
