WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_regionkey
),
part_suppliers AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
customer_orders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, COALESCE((SELECT MAX(o.o_orderkey)
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_suppkey = s.s_suppkey AND l.l_returnflag = 'R'), -1) AS last_order,
        CASE WHEN s.s_acctbal IS NULL THEN 'No Balance' ELSE 'With Balance' END AS balance_status
    FROM supplier s
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ps.unique_suppliers, 0) AS suppliers_count,
    pi.total_revenue AS total_revenue,
    ROW_NUMBER() OVER(PARTITION BY r.r_regionkey ORDER BY pi.total_revenue DESC) AS region_rank,
    ni.n_name AS nation_name,
    CASE WHEN s.last_order = -1 THEN 'Never Ordered' ELSE 'Ordered' END AS order_status,
    s.balance_status
FROM part p
LEFT JOIN part_suppliers ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN customer_orders pi ON pi.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT nh.n_nationkey FROM nation_hierarchy nh WHERE nh.level = 0 AND nh.n_regionkey IS NOT NULL LIMIT 1))
LEFT JOIN nation ni ON ni.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = pi.o_custkey)
LEFT JOIN supplier_info s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ps.ps_partkey LIMIT 1)
JOIN region r ON ni.n_regionkey = r.r_regionkey 
WHERE p.p_retailprice > (SELECT AVG(p.p_retailprice) FROM part p)
    AND s.s_acctbal IS NOT NULL
ORDER BY p.p_partkey, r.r_name;
