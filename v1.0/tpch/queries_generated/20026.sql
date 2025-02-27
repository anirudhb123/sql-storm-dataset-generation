WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IN (SELECT DISTINCT s_nationkey FROM supplier)
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_regionkey
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > (
        SELECT AVG(o2.o_totalprice) FROM orders o2
        WHERE o2.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
    )
)
SELECT
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ss.s_name AS supplier_name,
    ss.total_cost,
    fo.o_orderkey,
    fo.o_totalprice
FROM region r
LEFT JOIN nation_hierarchy ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN supplier_summary ss ON ss.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2 
            WHERE p2.p_size IS NOT NULL
        )
    )
)
LEFT JOIN filtered_orders fo ON fo.o_custkey IN (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_acctbal BETWEEN 1000 AND 5000
)
WHERE ss.total_cost IS NOT NULL
  AND ns.level = (SELECT MAX(level) FROM nation_hierarchy)
  AND r.r_name NOT LIKE '%OVER%'
ORDER BY ss.total_cost DESC, fo.o_totalprice ASC
LIMIT 10;
