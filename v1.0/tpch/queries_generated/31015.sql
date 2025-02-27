WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1 
    FROM nation n
    INNER JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) OVER (PARTITION BY c.c_custkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_avg_cost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(sa.avg_supplycost, 0) AS avg_supplycost,
    cs.total_spent,
    nh.level AS nation_level,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE 'Active Customer'
    END AS customer_status
FROM part p
LEFT JOIN supplier_avg_cost sa ON p.p_partkey = sa.ps_partkey
LEFT JOIN customer_summary cs ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (
    SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Germany' LIMIT 1) LIMIT 1)
LEFT JOIN nation_hierarchy nh ON nh.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = cs.c_custkey)
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 10)
ORDER BY p.p_partkey;
