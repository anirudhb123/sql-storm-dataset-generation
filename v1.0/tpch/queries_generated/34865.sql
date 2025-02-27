WITH RECURSIVE order_hierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, o_orderstatus
    FROM orders
    WHERE o_orderstatus = 'O' AND o_orderdate >= DATE '2023-01-01'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice + oh.o_totalprice, o.o_orderstatus
    FROM orders o
    JOIN order_hierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),

customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

lineitem_analysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),

supplier_performance AS (
    SELECT s.s_suppkey, COUNT(DISTINCT ps.ps_partkey) AS total_parts, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),

region_nation AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_name, r.r_name
)

SELECT
    cs.c_name,
    cs.total_spent,
    COALESCE(la.total_revenue, 0) AS revenue,
    sp.total_parts,
    sp.avg_supplycost,
    rn.nation_name,
    rn.region_name
FROM customer_summary cs
LEFT JOIN lineitem_analysis la ON la.l_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = cs.c_custkey)
LEFT JOIN supplier_performance sp ON sp.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE p.p_brand = 'Brand#23' AND ps.ps_availqty > 0
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
JOIN region_nation rn ON cs.c_nationkey = (
    SELECT n.n_nationkey 
    FROM nation n 
    WHERE n.n_name LIKE '%land%'
    LIMIT 1
)
WHERE cs.total_spent > 1000
ORDER BY cs.total_spent DESC, revenue DESC;
