WITH RECURSIVE price_history AS (
    SELECT ps.partkey, ps.suppkey, ps.availqty, ps.supplycost, 1 AS level
    FROM partsupp ps
    WHERE ps.availqty > 0
    UNION ALL
    SELECT ps.partkey, ps.suppkey, ps.availqty, ps.supplycost * 1.05 AS supplycost, ph.level + 1
    FROM partsupp ps
    JOIN price_history ph ON ps.partkey = ph.partkey AND ph.level < 5
), cust_order_totals AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
), line_items_with_discount AS (
    SELECT l.*, 
           (l.l_extendedprice * (1 - l.l_discount)) AS net_price, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_seq
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
), supplier_part_info AS (
    SELECT s.s_name, p.p_name, SUM(ps.ps_availqty) AS total_avail
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_name, p.p_name
    HAVING SUM(ps.ps_availqty) > 100
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(pt.total_spent) AS avg_customer_spent,
    SUM(DISTINCT pi.total_avail) AS total_supplier_parts,
    SUM(l.net_price) AS total_net_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN cust_order_totals pt ON c.c_custkey = pt.c_custkey
LEFT JOIN supplier_part_info pi ON pi.s_name = (
    SELECT s_name FROM supplier WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp)
)
LEFT JOIN line_items_with_discount l ON c.c_custkey IN (
    SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey
)
GROUP BY r.r_name
HAVING SUM(l.net_price) > 10000 OR COUNT(DISTINCT c.c_custkey) > 50
ORDER BY total_customers DESC, avg_customer_spent DESC;
