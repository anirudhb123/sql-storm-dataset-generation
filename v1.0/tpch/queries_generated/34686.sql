WITH RECURSIVE sup_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    WHERE s.s_acctbal > 1000
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) as total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
        WHERE o2.o_orderstatus = 'O'
    )
),
part_supplier_counts AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) as supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
comments AS (
    SELECT p.p_partkey, p.p_comment, 
           COALESCE(NULLIF(p.p_comment, ''), 'No comment') as adjusted_comment
    FROM part p
),
final_summary AS (
    SELECT 
        n.n_name as nation,
        COUNT(DISTINCT c.c_custkey) as customer_count,
        SUM(li.l_extendedprice * (1 - li.l_discount)) as total_revenue,
        AVG(li.l_quantity) as avg_quantity,
        MAX(s.s_acctbal) as max_supplier_acctbal,
        ARRAY_AGG(DISTINCT c.c_name) as top_customers_list
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT f.nation, f.customer_count, f.total_revenue, f.avg_quantity, f.max_supplier_acctbal,
       sd.s_name as top_supplier, 
       CASE WHEN f.customer_count IS NULL THEN 'No customers' ELSE 'Customers exist' END as customer_status
FROM final_summary f
LEFT JOIN sup_details sd ON f.max_supplier_acctbal = sd.s_acctbal
ORDER BY f.total_revenue DESC, f.nation;
