WITH RECURSIVE supplier_totals AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, st.total_supplycost + SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier_totals st
    JOIN supplier s ON s.s_suppkey = st.s_suppkey + 1 -- Example recursive relationship
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, st.total_supplycost
),
customer_avg_spending AS (
    SELECT c.c_custkey, AVG(o.o_totalprice) AS avg_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
high_spenders AS (
    SELECT c.c_custkey, c.c_name, ca.avg_spending
    FROM customer c
    JOIN customer_avg_spending ca ON c.c_custkey = ca.c_custkey
    WHERE ca.avg_spending > (SELECT AVG(avg_spending) FROM customer_avg_spending)
),
part_order_summary AS (
    SELECT p.p_name, COUNT(l.l_orderkey) AS order_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_name
)
SELECT 
    r.r_name, 
    ns.nation_total, 
    ps.total_supplycost,
    h.avg_spending,
    ps.order_count,
    ps.revenue
FROM region r
LEFT JOIN (
    SELECT n.n_regionkey, COUNT(*) AS nation_total
    FROM nation n
    GROUP BY n.n_regionkey
) ns ON r.r_regionkey = ns.n_regionkey
JOIN supplier_totals ps ON ps.s_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey) LIMIT 1)
JOIN high_spenders h ON h.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = r.r_regionkey) LIMIT 1)
JOIN part_order_summary ps ON ps.order_count > 0
ORDER BY r.r_name, ps.revenue DESC
LIMIT 10;
