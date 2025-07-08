
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderStats AS (
    SELECT o.o_orderkey, 
           COUNT(l.l_orderkey) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           SUM(l.l_discount) AS total_discount,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS return_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerRanked AS (
    SELECT c.c_custkey, 
           c.c_name,
           DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS balance_rank,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ph.p_partkey, 
    ph.p_name, 
    ph.p_brand, 
    COALESCE(r.r_name, 'Unknown Region') AS region_name,
    SUM(COALESCE(p.ps_availqty, 0)) AS total_available_quantity,
    MAX(os.total_sales) AS max_sale_per_order,
    SUM(COALESCE(cs.order_count, 0)) AS total_customer_orders,
    LISTAGG(DISTINCT sh.s_name, ', ') WITHIN GROUP (ORDER BY sh.s_name) AS dedicated_suppliers
FROM part ph
LEFT JOIN partsupp p ON ph.p_partkey = p.ps_partkey
LEFT JOIN nation n ON p.ps_suppkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN OrderStats os ON os.line_count > 1
LEFT JOIN CustomerRanked cs ON cs.balance_rank BETWEEN 1 AND 10
LEFT JOIN SupplierHierarchy sh ON ph.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = sh.s_suppkey)
WHERE ph.p_size IS NOT NULL
AND (ph.p_container LIKE '%box%' OR ph.p_container LIKE '%pack%')
AND (ph.p_retailprice > 100 OR ph.p_retailprice < 10)
GROUP BY ph.p_partkey, ph.p_name, ph.p_brand, r.r_name
HAVING MAX(os.total_discount) < 0.25 
   OR SUM(COALESCE(cs.order_count, 0)) > 5
ORDER BY ph.p_partkey DESC
LIMIT 15;
