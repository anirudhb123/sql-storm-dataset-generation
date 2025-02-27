WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_address, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_address, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
HighValueLines AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_totalprice > 5000
),
AggregatedData AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, 
           SUM(hvl.l_extendedprice * (1 - hvl.l_discount)) AS total_sales,
           COUNT(DISTINCT hvl.l_orderkey) AS order_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN HighValueLines hvl ON p.p_partkey = hvl.l_partkey
    GROUP BY p.p_partkey, p.p_name, ps.ps_supplycost
),
FinalReport AS (
    SELECT ad.p_partkey, ad.p_name, ad.ps_supplycost, 
           ad.total_sales, ad.order_count,
           COALESCE(sh.s_name, 'No Supplier') AS supplier_name,
           RANK() OVER (PARTITION BY ad.p_partkey ORDER BY ad.total_sales DESC) AS sales_rank
    FROM AggregatedData ad
    LEFT JOIN SupplierHierarchy sh ON ad.ps_supplycost = sh.s_acctbal
)
SELECT fr.p_partkey, fr.p_name, fr.ps_supplycost,
       fr.total_sales, fr.order_count, fr.supplier_name,
       CASE WHEN fr.sales_rank <= 5 THEN 'Top Seller' ELSE 'Regular Seller' END AS seller_category
FROM FinalReport fr
WHERE fr.total_sales IS NOT NULL AND fr.order_count > 10
ORDER BY fr.total_sales DESC, fr.p_partkey;
