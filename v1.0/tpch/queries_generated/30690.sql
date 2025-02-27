WITH RECURSIVE SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
    UNION ALL
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) + ss.total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.total_sales < 100000
    GROUP BY s.s_suppkey, s.s_name
)
SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS num_customers, 
       AVG(o.o_totalprice) AS avg_order_value,
       MAX(COALESCE(ss.total_sales, 0)) AS max_supplier_sales,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE (n.n_name IS NOT NULL AND c.c_acctbal > 500 OR c.c_comment LIKE '%important%')
GROUP BY n.n_name
HAVING avg(o.o_totalprice) > 1000
ORDER BY max_supplier_sales DESC NULLS LAST
LIMIT 10;
