
WITH RECURSIVE top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ts.total_cost
    FROM top_suppliers ts
    JOIN supplier s ON ts.total_cost > s.s_acctbal
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
ranked_customers AS (
    SELECT c.*, RANK() OVER (ORDER BY total_spent DESC) AS spending_rank
    FROM customer_orders c
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    SUM(l.l_quantity) AS total_quantity_sold,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COALESCE(rcc.total_count, 0) AS customer_count,
    CASE WHEN l.l_shipdate > DATE '1997-10-01' THEN 'Recent' ELSE 'Old' END AS sale_period
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN (
    SELECT rc.c_custkey, rc.c_name, COUNT(*) AS total_count
    FROM ranked_customers rc
    LEFT JOIN orders o ON rc.c_custkey = o.o_custkey
    GROUP BY rc.c_custkey, rc.c_name
) rcc ON rcc.c_custkey = l.l_orderkey
GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, sale_period, rcc.total_count
HAVING SUM(l.l_quantity) > 50 AND SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY total_sales DESC
LIMIT 10;
