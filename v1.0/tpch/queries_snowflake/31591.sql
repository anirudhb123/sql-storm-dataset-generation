WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
Recent_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM orders o
    WHERE o.o_orderdate > (cast('1998-10-01' as date) - INTERVAL '1 year')
),
LineItemSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name AS supplier_name, ps.ps_availqty, ps.ps_supplycost
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 50
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS average_order_value,
    SUM(ls.total_revenue) AS total_lineitem_revenue,
    MAX(sh.level) AS supplier_hierarchy_level
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN Recent_orders o ON o.o_custkey = c.c_custkey
LEFT JOIN LineItemSummary ls ON ls.l_orderkey = o.o_orderkey
LEFT JOIN SupplierPartDetails spd ON spd.ps_suppkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = spd.ps_suppkey
WHERE r.r_name IS NOT NULL
GROUP BY n.n_name, r.r_name
HAVING AVG(o.o_totalprice) > 500
ORDER BY nation_name, region_name;