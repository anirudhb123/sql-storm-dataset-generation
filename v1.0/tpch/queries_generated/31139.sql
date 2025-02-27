WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier) 
    AND sh.level < 5
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
customer_analysis AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_amount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
)
SELECT r.r_name, SUM(p.ps_supplycost) AS total_supply_cost,
       (SELECT COUNT(*) FROM supplier_hierarchy) AS active_suppliers,
       (SELECT COUNT(*) FROM ranked_orders WHERE order_rank <= 10) AS top_orders
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
JOIN customer_analysis ca ON ca.c_mktsegment = 'BUILDING'
WHERE r.r_name IS NOT NULL AND p.ps_availqty > 0
GROUP BY r.r_name
HAVING COUNT(s.s_suppkey) > 5
ORDER BY total_supply_cost DESC
LIMIT 10;
