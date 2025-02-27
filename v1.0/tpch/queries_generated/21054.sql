WITH RECURSIVE SupportRoles AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 1 as level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
      AND s_comment IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, sr.level + 1
    FROM supplier s
    JOIN SupportRoles sr ON sr.suppkey = s.suppkey
    WHERE s.s_acctbal < sr.s_acctbal
      AND sr.level < 10
),
ProductStatistics AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(l.l_quantity) AS total_quantity, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F') 
      AND o.o_orderdate >= '2023-01-01'
),
CombinedResults AS (
    SELECT ps.p_partkey, ps.supplier_count, ps.total_quantity, ps.total_sales,
           o.price_rank, r.r_name, n.n_name
    FROM ProductStatistics ps
    LEFT JOIN HighValueOrders o ON ps.supplier_count <= o.price_rank
    JOIN supplier s ON ps.supplier_count = (SELECT COUNT(*) FROM partsupp WHERE ps.p_partkey = ps.ps_partkey)
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
FinalOutput AS (
    SELECT c.p_partkey, c.supplier_count, c.total_quantity, c.total_sales,
           COALESCE(SUM(l.l_discount), 0) AS total_discount,
           CASE 
               WHEN c.total_sales > 10000 THEN 'High Value' 
               ELSE 'Standard' 
           END AS value_category
    FROM CombinedResults c
    LEFT JOIN lineitem l ON c.p_partkey = l.l_partkey
    GROUP BY c.p_partkey, c.supplier_count, c.total_quantity, c.total_sales
)
SELECT p.p_name, f.value_category, f.total_sales, f.total_discount, 
       (CASE WHEN f.total_discount IS NULL THEN 'NO DISCOUNT' ELSE 'DISCOUNT APPLIED' END) as discount_status
FROM FinalOutput f
JOIN part p ON p.p_partkey = f.p_partkey
WHERE (f.total_sales - f.total_discount) > 5000
ORDER BY f.total_sales DESC, p.p_name
LIMIT 10
OFFSET 0;
