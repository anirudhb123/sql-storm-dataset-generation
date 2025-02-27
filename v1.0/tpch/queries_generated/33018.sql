WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000.00 AND sh.level < 3
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_partkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_orderkey
),
SupplierSales AS (
    SELECT s.s_suppkey, SUM(l.l_extendedprice) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY s.s_suppkey
),
FilteredSales AS (
    SELECT ss.s_suppkey, ss.total_supply_cost, os.total_sales, os.item_count
    FROM SupplierSales ss
    LEFT JOIN OrderStats os ON ss.s_suppkey = os.o_orderkey
    WHERE ss.total_supply_cost IS NOT NULL
),
RankedSales AS (
    SELECT fs.*, RANK() OVER (PARTITION BY fs.item_count ORDER BY fs.total_sales DESC) AS rank
    FROM FilteredSales fs
)

SELECT rh.s_name, rh.level, 
       COALESCE(rs.total_sales, 0) AS total_sales,
       COALESCE(rs.item_count, 0) AS item_count,
       CASE 
           WHEN rs.rank IS NOT NULL THEN 'Ranked'
           ELSE 'Unranked'
       END AS sales_rank_status
FROM SupplierHierarchy rh
LEFT JOIN RankedSales rs ON rh.s_suppkey = rs.s_suppkey
WHERE rh.level < 3 AND rh.s_nationkey IN (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_comment LIKE '%good%'
) 
ORDER BY rh.level, total_sales DESC, rh.s_name;
