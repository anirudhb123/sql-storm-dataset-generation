WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_stats AS (
    SELECT s.s_nationkey, COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(s.s_acctbal) AS total_account_balance
    FROM supplier s
    JOIN nation_hierarchy nh ON s.s_nationkey = nh.n_nationkey
    GROUP BY s.s_nationkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' 
      AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, 
           COALESCE(SUM(os.total_value), 0) AS total_spending
    FROM customer c
    LEFT JOIN order_summary os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
),
final_analysis AS (
    SELECT cs.c_mktsegment, COUNT(cs.c_custkey) AS total_customers,
           AVG(cs.total_spending) AS avg_spending,
           MAX(ss.total_suppliers) AS max_suppliers,
           SUM(ss.total_account_balance) AS total_balance
    FROM customer_summary cs
    LEFT JOIN supplier_stats ss ON cs.total_spending > 1000
    GROUP BY cs.c_mktsegment
)

SELECT fh.*, r.r_name
FROM final_analysis fh
JOIN region r ON fh.max_suppliers > (SELECT AVG(total_suppliers) FROM supplier_stats)
WHERE fh.avg_spending IS NOT NULL
ORDER BY fh.total_customers DESC, fh.avg_spending DESC;
