
WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '1997-01-01'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
),
CustomerSegment AS (
    SELECT c.c_custkey, c.c_mktsegment, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_mktsegment
),
SupplierStats AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
),
AggregatedLineItems AS (
    SELECT l.l_orderkey, COUNT(*) AS line_count, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name AS nation,
    r.r_name AS region,
    COUNT(DISTINCT css.c_custkey) AS customer_count,
    SUM(cli.total_revenue) AS total_revenue,
    AVG(css.total_spent) AS avg_customer_spend,
    MAX(ss.total_supplycost) AS max_supplier_cost
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerSegment css ON n.n_nationkey = css.c_custkey
LEFT JOIN orders o ON css.c_custkey = o.o_custkey
LEFT JOIN AggregatedLineItems cli ON o.o_orderkey = cli.l_orderkey
LEFT JOIN SupplierStats ss ON cli.line_count > 0
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT css.c_custkey) > 0
ORDER BY total_revenue DESC, avg_customer_spend DESC;
