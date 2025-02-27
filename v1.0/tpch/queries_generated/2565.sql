WITH supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name
    FROM customer_orders c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name AS nation_name,
    p.p_name,
    COALESCE(su.total_supply_cost, 0) AS supplier_cost,
    COALESCE(cu.order_count, 0) AS customer_order_count,
    l.total_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_summary su ON ps.ps_suppkey = su.s_suppkey
LEFT JOIN high_value_customers cu ON cu.c_custkey = ps.ps_suppkey
LEFT JOIN lineitem_summary l ON l.l_orderkey = p.p_partkey
JOIN nation n ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = ps.ps_suppkey)
WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY nation_name, supplier_cost DESC, customer_order_count DESC;
