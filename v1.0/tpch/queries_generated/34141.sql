WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '2021-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC)
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN order_hierarchy oh ON o.o_orderkey = oh.o_orderkey + 1
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, s.s_name, ps.ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
order_details AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
supplier_revenue AS (
    SELECT s.s_name, SUM(od.total_revenue) AS total_revenue
    FROM supplier s
    LEFT JOIN part_supplier ps ON s.s_suppkey = ps.s_suppkey
    LEFT JOIN order_details od ON ps.p_partkey IN (SELECT p_partkey FROM part WHERE p_name ILIKE '%widget%')
    GROUP BY s.s_name
)
SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, oh.c_mktsegment, 
       COALESCE(sr.total_revenue, 0) AS supplier_revenue
FROM order_hierarchy oh
LEFT JOIN supplier_revenue sr ON sr.s_name = (SELECT s.s_name FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') LIMIT 1)
WHERE oh.rank <= 10
ORDER BY oh.o_totalprice DESC
LIMIT 100;
