WITH RECURSIVE suppliers_above_average AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           AVG(s2.s_acctbal) OVER () AS avg_acctbal 
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
part_supplier_count AS (
    SELECT ps.ps_partkey, COUNT(*) AS supplier_count
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
high_demand_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.supplier_count
    FROM part p
    JOIN part_supplier_count ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.supplier_count > 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
total_revenue AS (
    SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
),
final_selection AS (
    SELECT c.c_custkey, c.c_name, h.p_name,
           (CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE ROUND(s.s_acctbal, 2) END) AS supplier_balance
    FROM customer_orders c
    LEFT JOIN suppliers_above_average s ON c.c_custkey % 5 = s.s_suppkey % 5
    JOIN high_demand_parts h ON h.p_partkey = c.c_custkey % (SELECT COUNT(*) FROM part)
)
SELECT f.c_custkey, f.c_name, f.p_name,
       (SELECT (AVG(total_revenue.total_revenue) OVER ()) * 100
        FROM total_revenue) AS normalized_revenue
FROM final_selection f
WHERE f.supplier_balance > 0
    AND f.supplier_balance IS NOT DISTINCT FROM 
        (SELECT MAX(s.s_acctbal) FROM suppliers_above_average s)
ORDER BY f.c_custkey DESC, f.supplier_balance DESC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM customer_orders) / 10;
