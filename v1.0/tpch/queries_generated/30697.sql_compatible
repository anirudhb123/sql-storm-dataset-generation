
WITH RECURSIVE order_hierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= DATE '1995-01-01' AND o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN order_hierarchy oh ON o.o_orderkey > oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
supplier_stats AS (
    SELECT s.s_suppkey, s.s_name, 
           COUNT(ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost) AS total_supplycost,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
lineitem_summary AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_linenumber) AS total_items
    FROM lineitem l
    GROUP BY l.l_orderkey
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)

SELECT 
    ns.r_name AS region,
    cs.c_custkey,
    cs.order_count,
    cs.total_spent,
    ss.total_parts,
    ss.total_supplycost,
    lhs.total_revenue,
    ROW_NUMBER() OVER (PARTITION BY ns.r_regionkey ORDER BY cs.total_spent DESC) AS rank_within_region
FROM customer_orders cs
JOIN supplier_stats ss ON cs.order_count > 0
LEFT JOIN lineitem_summary lhs ON lhs.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
JOIN nation_region ns ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey LIMIT 1)
WHERE cs.total_spent IS NOT NULL
ORDER BY cs.total_spent DESC, ns.r_name ASC;
