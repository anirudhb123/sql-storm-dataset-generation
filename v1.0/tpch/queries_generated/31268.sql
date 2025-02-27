WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CAST(s.s_name AS varchar(100)) AS supplier_path
    FROM supplier s
    WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.nationkey,
           CONCAT(sh.supplier_path, ' -> ', s.s_name)
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.s_suppkey <> s.s_suppkey
),
orders_summary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.o_custkey
)
SELECT c.c_name, c.c_acctbal, 
       COALESCE(total_revenue, 0) AS customer_revenue,
       s.s_name AS supplier_name,
       rh.supplier_path
FROM customer c
LEFT JOIN orders_summary os ON c.c_custkey = os.o_custkey
LEFT JOIN supplier_hierarchy rh ON rh.s_nationkey = c.c_nationkey
LEFT JOIN supplier s ON s.s_nationkey = c.c_nationkey
WHERE c.c_acctbal > (
    SELECT AVG(c2.c_acctbal) 
    FROM customer c2 
    WHERE c2.c_nationkey = c.c_nationkey
) 
AND os.revenue_rank <= 5
ORDER BY c.c_name, customer_revenue DESC;

