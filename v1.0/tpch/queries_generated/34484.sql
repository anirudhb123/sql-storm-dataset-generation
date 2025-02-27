WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY l.l_partkey
),
TopParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COALESCE(ts.total_sales, 0) AS sales,
        ROW_NUMBER() OVER(ORDER BY COALESCE(ts.total_sales, 0) DESC) AS rank
    FROM part p
    LEFT JOIN TotalSales ts ON p.p_partkey = ts.l_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN ts.sales > 5000 THEN 1 ELSE 0 END) AS high_sales_count,
    MAX(ts.sales) AS max_sales,
    AVG(ts.sales) AS avg_sales
FROM nation n
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN TopParts ts ON ts.rank <= 5
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY nation_name;
