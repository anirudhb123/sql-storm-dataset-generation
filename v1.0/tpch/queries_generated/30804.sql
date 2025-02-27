WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey, n.n_name, 
           CAST(s.s_name AS VARCHAR(55)) AS supplier_path
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_acctbal, n.n_nationkey, n.n_name,
           CAST(concat(sh.supplier_path, ' -> ', n.n_name) AS VARCHAR(55))
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_suppkey = sh.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE sh.s_acctbal < 50000
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey
),
supply_analysis AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_order_analysis AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY COUNT(o.o_orderkey) DESC) AS rank_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT s.s_name, s.s_acctbal, n.n_name AS supplier_nation,
       coalesce(os.total_revenue, 0) AS order_revenue,
       sa.total_supply_cost,
       CASE 
           WHEN sa.total_supply_cost IS NULL THEN 'No Supply Cost'
           ELSE 'Supply Cost Present'
       END AS supply_cost_status
FROM supplier_hierarchy s
FULL OUTER JOIN order_summary os ON s.s_suppkey = os.o_orderkey
FULL OUTER JOIN supply_analysis sa ON s.s_suppkey = sa.p_partkey
JOIN nation n ON s.n_nationkey = n.n_nationkey
WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) 
   AND (os.total_revenue IS NOT NULL OR sa.total_supply_cost IS NOT NULL)
ORDER BY s.s_name, supplier_nation DESC
FETCH FIRST 100 ROWS ONLY;
