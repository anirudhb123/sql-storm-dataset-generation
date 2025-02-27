WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
), 

SalesData AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY c.c_custkey
)

SELECT 
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    p.p_retailprice,
    COALESCE(ps.ps_availqty, 0) AS available_qty,
    CASE WHEN COUNT(DISTINCT li.l_orderkey) IS NULL THEN 'No Sales' ELSE 'Sold' END AS sales_status,
    ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS price_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN SalesData sd ON sd.c_custkey = li.l_orderkey
WHERE p.p_size > 10
  AND (p.p_comment LIKE '%special%' OR p.p_retailprice < 50.00)
GROUP BY p.p_partkey, ps.ps_availqty, p.p_name, p.p_brand, p.p_mfgr, p.p_retailprice
HAVING SUM(li.l_discount) > 0.1 OR COUNT(DISTINCT li.l_orderkey) > 5
ORDER BY price_rank, p.p_name;