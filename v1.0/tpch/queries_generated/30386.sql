WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationSales AS (
    SELECT n.n_nationkey, n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
RankedPartSales AS (
    SELECT p_partkey, p_name, total_sales, 
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM PartSales
)
SELECT 
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    p.p_name AS part_name,
    ps.total_sales AS part_total_sales,
    sh.level AS supplier_level,
    ns.total_supply_cost AS total_supply_cost,
    CASE 
        WHEN ps.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM region r
LEFT JOIN nation ns ON ns.n_regionkey = r.r_regionkey
LEFT JOIN RankedPartSales ps ON ns.n_nationkey = ps.p_partkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = ns.n_nationkey
WHERE r.r_name LIKE '%America%'
  AND (ps.total_sales > 50000 OR ps.total_sales IS NULL)
ORDER BY r.r_name, ns.n_name, ps.total_sales DESC;
