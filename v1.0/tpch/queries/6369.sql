
WITH supplier_part AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_order AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'A' AND o.o_totalprice > 1000
),
line_item_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT sp.s_name, c.c_name AS customer_name, c.o_orderdate, l.total_revenue, COUNT(DISTINCT sp.p_partkey) AS part_count
FROM supplier_part sp
JOIN customer_order c ON sp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey)
JOIN line_item_summary l ON c.o_orderkey = l.l_orderkey
GROUP BY sp.s_name, c.c_name, c.o_orderdate, l.total_revenue
ORDER BY l.total_revenue DESC, sp.s_name;
