WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 10000 AND sh.level < 5
),
TotalSales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        NTILE(5) OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount))) AS sales_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
HighValueSales AS (
    SELECT 
        t.c_custkey,
        t.total_sales,
        COALESCE(r.r_name, 'Unknown Region') AS region_name
    FROM TotalSales t
    LEFT JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = t.c_custkey)
    LEFT JOIN region r ON r.r_regionkey = n.n_regionkey
    WHERE t.total_sales > 5000
)
SELECT 
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns,
    AVG(l.l_discount) AS average_discount,
    sh.level AS supplier_level
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN HighValueSales hvs ON hvs.c_custkey = l.l_orderkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE p.p_size <> 0 
AND p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) 
    FROM part p2 
    WHERE p2.p_type LIKE '%plastic%'
) 
AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY p.p_name, p.p_brand, sh.level
HAVING COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY order_count DESC, returns ASC;