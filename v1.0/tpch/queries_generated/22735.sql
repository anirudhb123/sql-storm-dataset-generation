WITH RECURSIVE detailed_parts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           COALESCE(SUM(line.l_extendedprice * (1 - line.l_discount)), 0) AS total_sales,
           row_number() OVER (PARTITION BY p.p_partkey ORDER BY SUM(line.l_extendedprice * (1 - line.l_discount)) DESC) AS rn
    FROM part p
    LEFT JOIN lineitem line ON p.p_partkey = line.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
),
filtered_suppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal,
           CASE
               WHEN s.s_acctbal IS NULL THEN 'Low Balance Supplier'
               WHEN s.s_acctbal >= 10000 THEN 'High Balance Supplier'
               ELSE 'Medium Balance Supplier'
           END AS balance_category
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
)
SELECT d.p_name, 
       d.total_sales, 
       f.balance_category,
       COUNT(DISTINCT f.s_suppkey) OVER (PARTITION BY f.balance_category) AS supplier_count,
       CASE 
           WHEN AVG(f.s_acctbal) OVER (PARTITION BY f.balance_category) > 50000 THEN 'Wealthy Segment'
           ELSE 'Standard Segment'
       END AS segment,
       (SELECT COUNT(*) FROM orders o WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31' AND o.o_totalprice > 1000) AS high_value_orders
FROM detailed_parts d
JOIN partsupp ps ON d.p_partkey = ps.ps_partkey
JOIN filtered_suppliers f ON ps.ps_suppkey = f.s_suppkey
WHERE d.rn = 1 
AND NOT EXISTS (
    SELECT 1 FROM nation n
    WHERE n.n_nationkey = f.s_nationkey AND n.n_comment IS NULL
)
ORDER BY d.total_sales DESC, f.s_acctbal ASC;
