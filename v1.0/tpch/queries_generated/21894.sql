WITH RECURSIVE supply_chain AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) as rank
    FROM partsupp
    WHERE ps_availqty > 0
), 
order_summary AS (
    SELECT o.custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS status_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY o.custkey
),
high_value_customers AS (
    SELECT c.custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)
SELECT c.c_name, 
       COALESCE(s.name, 'No Supplier') AS supplier_name,
       SUM(ss.ps_availqty) AS total_available_quantity,
       MAX(oss.total_revenue) AS max_revenue,
       CASE WHEN MAX(oss.total_revenue) IS NULL THEN 'No Orders' 
            ELSE 'Orders Exist' END AS order_status,
       NULLIF(MIN(o.o_orderpriority), 'normal') AS special_order_priority
FROM high_value_customers hvc
LEFT JOIN supply_chain ss ON hvc.custkey = ss.ps_suppkey
LEFT JOIN supplier s ON ss.ps_suppkey = s.s_suppkey
LEFT JOIN order_summary oss ON hvc.custkey = oss.custkey
LEFT JOIN orders o ON oss.order_count > 1 AND o.o_custkey = hvc.custkey
GROUP BY c.c_name, s.name
HAVING COUNT(ss.ps_partkey) > 0 OR MAX(oss.total_revenue) IS NOT NULL
ORDER BY total_available_quantity DESC, c.c_name ASC;
