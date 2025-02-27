WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
part_availability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
customer_sales AS (
    SELECT c.c_custkey, SUM(os.total_revenue) AS total_spent
    FROM customer c
    LEFT JOIN order_summary os ON c.c_custkey = o.o_custkey
    JOIN orders o ON os.o_orderkey = o.o_orderkey
    GROUP BY c.c_custkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(pa.total_availqty, 0) AS total_availqty,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Purchases'
        ELSE CONCAT('Total Spent: $', ROUND(cs.total_spent, 2))
    END AS purchase_summary,
    sh.level AS supplier_level
FROM part p
LEFT JOIN part_availability pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN customer_sales cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE 'Customer%')
LEFT JOIN supplier_hierarchy sh ON sh.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
ORDER BY total_availqty DESC, p.p_name;
