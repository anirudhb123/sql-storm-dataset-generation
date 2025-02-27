WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 1 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_custkey <> ch.c_custkey
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name
),
region_nation AS (
    SELECT r.r_regionkey, n.n_nationkey, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    ch.c_name AS customer_name,
    r.n_name AS nation_name,
    ss.s_name AS supplier_name,
    os.total_revenue,
    ss.total_supply_cost,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Orders'
        ELSE 'Orders Found'
    END AS order_status,
    ROW_NUMBER() OVER (PARTITION BY r.n_name ORDER BY os.total_revenue DESC) AS order_rank
FROM customer_hierarchy ch
LEFT JOIN order_summary os ON ch.c_custkey = os.o_orderkey
LEFT JOIN supplier_summary ss ON ss.total_supply_cost > 50
JOIN region_nation r ON ch.c_nationkey = r.n_nationkey
WHERE ch.level <= 3 AND 
      (ss.total_supply_cost IS NULL OR ss.total_supply_cost > 1000)
ORDER BY r.n_name, order_rank;
