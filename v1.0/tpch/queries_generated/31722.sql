WITH RECURSIVE regional_summary AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name, SUM(o.o_totalprice) + s.s_acctbal AS total_revenue
    FROM region r
    JOIN nation n ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN orders o ON s.s_suppkey = o.o_orderkey
    GROUP BY n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
),
part_summary AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, COUNT(*) AS line_count
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
customer_summary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS average_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
)
SELECT rs.r_name, ps.total_cost, ls.total_sales, cs.order_count, cs.average_order_value
FROM regional_summary rs
LEFT JOIN part_summary ps ON ps.p_partkey = (SELECT MIN(p.p_partkey) FROM part p)
LEFT JOIN lineitem_summary ls ON ls.l_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o)
LEFT JOIN customer_summary cs ON cs.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c)
WHERE rs.total_revenue > (SELECT AVG(rs2.total_revenue) FROM regional_summary rs2)
ORDER BY rs.r_name DESC, cs.average_order_value DESC
