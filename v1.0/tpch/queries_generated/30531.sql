WITH RECURSIVE ranked_orders AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice,
           RANK() OVER (PARTITION BY o_custkey ORDER BY o_totalprice DESC) AS rank_price
    FROM orders
), high_value_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
), supplier_part_info AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, 
           ps.ps_availqty, ps.ps_supplycost, 
           p.p_retailprice - ps.ps_supplycost AS profit_margin
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 100
)
SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    COALESCE(AVG(l.l_discount), 0) AS avg_discount,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returns,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(supply.ps_supplycost * supply.ps_availqty) AS total_supply_cost,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ' (', p.p_name, ')'), '; ') AS suppliers_info
FROM 
    region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN supplier_part_info supply ON s.s_suppkey = supply.s_suppkey
LEFT JOIN lineitem l ON supply.p_partkey = l.l_partkey
LEFT JOIN ranked_orders o ON o.o_custkey IN (SELECT c.c_custkey FROM high_value_customers c)
WHERE 
    l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
GROUP BY 
    r.r_name, 
    n.n_name, 
    c.c_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_orders DESC, 
    avg_discount DESC;
