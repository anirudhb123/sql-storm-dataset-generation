WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rnk
    FROM supplier
    WHERE s_acctbal > 1000
), 
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
), 
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(*) AS line_count,
           AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
), 
part_availability AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region_name, 
    ns.n_name AS nation_name,
    sh.s_name AS supplier_name,
    cos.c_name AS customer_name,
    cos.total_spent,
    los.revenue,
    p_av.total_available
FROM region r
JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN supplier_hierarchy sh ON ns.n_nationkey = sh.s_nationkey AND sh.rnk <= 5
JOIN customer_order_summary cos ON sh.s_nationkey = cos.c_custkey
JOIN lineitem_summary los ON cos.total_orders = (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = cos.c_custkey)
CROSS JOIN part_availability p_av
WHERE p_av.total_available IS NOT NULL
ORDER BY region_name, total_spent DESC, supplier_name;
