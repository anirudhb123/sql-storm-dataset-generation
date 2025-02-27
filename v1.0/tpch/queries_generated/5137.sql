WITH supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, p.p_brand, p.p_type, ps.ps_availqty, 
           ps.ps_supplycost, (ps.ps_availqty * ps.ps_supplycost) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
region_summary AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT rp.s_suppkey, rp.s_name, co.c_custkey, co.c_name, rs.r_name, 
       SUM(rp.total_value) AS total_parts_value, SUM(co.total_spent) AS total_customer_spent
FROM supplier_parts rp
JOIN customer_orders co ON rp.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = rp.s_suppkey)
JOIN region_summary rs ON EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = co.c_custkey AND n.n_regionkey = rs.r_regionkey)
GROUP BY rp.s_suppkey, rp.s_name, co.c_custkey, co.c_name, rs.r_name
HAVING SUM(rp.total_value) > 10000
ORDER BY total_parts_value DESC, total_customer_spent DESC;
