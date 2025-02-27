WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS orders_count,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supply_count,
    COALESCE(AVG(l.l_extendedprice * (1 - l.l_discount)), 0) AS avg_extended_price,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count,
    MAX(s.total_sales) AS max_sales,
    sr.r_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN SalesData sd ON sd.c_custkey = s.s_nationkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
WHERE p.p_retailprice > 10
GROUP BY p.p_partkey, p.p_name, p.p_brand, r.r_name
HAVING COUNT(DISTINCT ps.ps_suppkey) > 0 AND MAX(s.total_sales) IS NOT NULL
ORDER BY avg_extended_price DESC, return_count DESC;
