WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, s.s_comment, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(CASE WHEN l_returnflag = 'R' THEN l_quantity ELSE 0 END) AS total_returned_qty,
       SUM(CASE WHEN l_shipdate > CURRENT_DATE THEN l_extendedprice * (1 - l_discount) ELSE NULL END) AS future_sales_value,
       STRING_AGG(DISTINCT concat_ws('|', p.p_name, p.p_comment)) AS product_details
FROM nation n
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
JOIN part p ON l.l_partkey = p.p_partkey
JOIN SupplierHierarchy sh ON sh.s_suppkey = c.c_custkey % (SELECT COUNT(*) FROM supplier)
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > (SELECT AVG(cust_count) FROM (SELECT COUNT(DISTINCT c.c_custkey) AS cust_count 
                                                           FROM customer c 
                                                           GROUP BY c.c_nationkey) AS temp)
ORDER BY total_returned_qty DESC, future_sales_value DESC
FETCH FIRST 5 ROWS ONLY;
