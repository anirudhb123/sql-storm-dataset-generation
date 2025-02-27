WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RegionSales AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS total_sales
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
),
TopProducts AS (
    SELECT p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000.00
),
CustomerOrderStats AS (
    SELECT c.c_name, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_name
)
SELECT rh.r_name, COALESCE(rs.total_sales, 0) AS total_region_sales, 
       CASE 
           WHEN ts.revenue IS NOT NULL THEN ts.revenue 
           ELSE 0 
       END AS top_product_revenue, 
       cos.order_count, cos.avg_order_value
FROM RegionSales rs
FULL OUTER JOIN TopProducts ts ON ts.revenue > 0
JOIN Region r ON r.r_name = rs.r_name
LEFT JOIN CustomerOrderStats cos ON cos.avg_order_value IS NOT NULL
WHERE r.r_name IS NOT NULL 
ORDER BY total_region_sales DESC, top_product_revenue DESC
LIMIT 10;
