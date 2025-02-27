WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = 1 -- Assuming region key 1 is a base region
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           COUNT(DISTINCT l.l_orderkey) AS num_lineitems,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS value_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
region_supplier AS (
    SELECT r.r_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acct_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
)
SELECT r.region_name, 
       COALESCE(s.supplier_count, 0) AS supplier_count,
       COALESCE(s.total_acct_balance, 0) AS total_acct_balance,
       COALESCE(o.total_value, 0) AS order_value,
       COALESCE(o.num_lineitems, 0) AS lineitem_count
FROM (
    SELECT r.r_name AS region_name, 
           rs.supplier_count, 
           rs.total_acct_balance
    FROM region r
    JOIN region_supplier rs ON r.r_name = rs.r_name
) AS r
FULL OUTER JOIN order_summary o ON o.value_rank = 1
LEFT JOIN supplier_stats s ON s.total_cost IS NOT NULL
WHERE COALESCE(o.total_value, 0) > 10000
ORDER BY r.region_name;
