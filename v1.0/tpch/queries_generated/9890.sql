WITH top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
famous_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    t.s_name AS supplier_name,
    COUNT(DISTINCT hvo.o_orderkey) AS num_high_value_orders,
    SUM(hvo.o_totalprice) AS total_high_value_revenue,
    COUNT(DISTINCT fp.p_partkey) AS num_famous_parts
FROM top_suppliers t
LEFT JOIN high_value_orders hvo ON t.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    WHERE li.l_orderkey IN (SELECT o_orderkey FROM high_value_orders)
)
LEFT JOIN famous_parts fp ON fp.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_suppkey = t.s_suppkey
)
GROUP BY t.s_name
ORDER BY total_high_value_revenue DESC;
