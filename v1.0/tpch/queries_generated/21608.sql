WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 100.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal BETWEEN 1000 AND 5000 
      AND (o.o_orderstatus IS NULL OR o.o_orderstatus <> 'O')
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size % 5 = 0 OR p.p_mfgr LIKE '%Inc%'
),
TotalSales AS (
    SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
),
FinalResults AS (
    SELECT 
        sh.s_name AS supplier_name,
        COALESCE(c.c_name, 'No Orders') AS customer_name,
        pd.p_name AS part_name,
        pd.p_retailprice,
        COALESCE(ts.total_sales, 0) AS sales_for_year
    FROM SupplierHierarchy sh
    FULL OUTER JOIN CustomerOrders c ON sh.s_suppkey = c.o_orderkey
    CROSS JOIN PartDetails pd
    LEFT JOIN TotalSales ts ON pd.p_partkey = ts.total_sales
)
SELECT 
    supplier_name,
    customer_name,
    part_name,
    p_retailprice,
    sales_for_year,
    CASE 
        WHEN sales_for_year > 10000 THEN 'High Sales'
        WHEN sales_for_year BETWEEN 5000 AND 10000 THEN 'Medium Sales'
        ELSE 'Low Sales' 
    END AS sales_category
FROM FinalResults
WHERE (supplier_name IS NOT NULL AND customer_name IS NOT NULL)
   OR (supplier_name IS NULL AND customer_name IS NULL)
ORDER BY sales_category DESC, p_retailprice DESC;
