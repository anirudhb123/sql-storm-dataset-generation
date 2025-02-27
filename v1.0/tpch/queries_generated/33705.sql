WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
nation_orders AS (
    SELECT n.n_nationkey, n.n_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
),
performance_benchmark AS (
    SELECT n.n_name, nh.level, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM nation_orders n
    JOIN supplier_hierarchy nh ON n.n_nationkey = nh.s_nationkey
    JOIN partsupp ps ON nh.s_suppkey = ps.ps_suppkey
    WHERE n.order_count > 0
    GROUP BY n.n_name, nh.level
)
SELECT pb.n_name, pb.level, pb.total_supply_cost,
       ROW_NUMBER() OVER (PARTITION BY pb.n_name ORDER BY pb.total_supply_cost DESC) AS rank,
       COALESCE(NULLIF(pb.total_supply_cost, 0), NULL) AS adjusted_cost
FROM performance_benchmark pb
ORDER BY pb.n_name, pb.level;
