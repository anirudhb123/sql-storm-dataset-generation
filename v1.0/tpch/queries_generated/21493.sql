WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY s.s_acctbal DESC) AS rank_level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, sh.ps_availqty, sh.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY sh.s_suppkey ORDER BY sh.s_acctbal DESC) AS rank_level
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON ps.ps_partkey = (SELECT p.p_partkey FROM part p ORDER BY RANDOM() LIMIT 1)
    WHERE sh.rank_level < 5
),
TotalSales AS (
    SELECT o.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.c_custkey
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment LIKE 'B%'
)

SELECT 
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    c.c_name AS customer_name,
    ROUND(ts.total_sales, 2) AS total_sales,
    RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    CASE
        WHEN s.s_acctbal IS NULL THEN 'Balance Unknown'
        ELSE 'Balance Available'
    END AS balance_status
FROM SupplierHierarchy s
FULL OUTER JOIN FilteredCustomers c ON c.c_custkey = s.s_suppkey
LEFT JOIN TotalSales ts ON ts.c_custkey = c.c_custkey
LEFT JOIN part p ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 50 ORDER BY RANDOM() LIMIT 1)
WHERE s.ps_availqty > 0 OR c.c_nationkey IS NULL
GROUP BY supplier_name, customer_name, balance_status
HAVING COUNT(*) > 1 AND SUM(ts.total_sales) IS NOT NULL
ORDER BY sales_rank, supplier_name DESC NULLS LAST;
