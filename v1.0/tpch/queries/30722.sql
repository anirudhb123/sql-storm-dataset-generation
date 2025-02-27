WITH RECURSIVE SupplierTree AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal,
           CAST(s_name AS VARCHAR(255)) as full_path, 
           1 as level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CAST(CONCAT(st.full_path, ' -> ', s.s_name) AS VARCHAR(255)),
           st.level + 1
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN SupplierTree st ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#1')
)
SELECT n.n_name, r.r_name, COUNT(DISTINCT c.c_custkey) AS unique_customers,
       SUM(o.o_totalprice) AS total_spent,
       MAX(l.l_extendedprice) AS max_lineitem_price,
       AVG(s.s_acctbal) AS avg_supplier_balance, 
       CASE 
           WHEN MAX(l.l_discount) IS NULL THEN 'No Discount' 
           ELSE CONCAT('Max Discount: ', MAX(l.l_discount)) 
       END AS discount_info
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierTree st ON s.s_suppkey = st.s_suppkey
WHERE c.c_acctbal IS NOT NULL
  AND o.o_orderstatus = 'O'
  AND l.l_shipdate >= DATE '1997-01-01'
  AND l.l_shipdate < DATE '1998-01-01'
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_spent DESC, unique_customers ASC
LIMIT 10;