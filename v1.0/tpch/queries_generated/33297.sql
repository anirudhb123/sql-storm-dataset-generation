WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_parts AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
extreme_part AS (
    SELECT p.p_partkey, p.p_name, MAX(p.p_retailprice) AS max_price
    FROM part p
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    n.n_name,
    c.c_name,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    ep.max_price,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.total_spent DESC) AS rank
FROM nation_hierarchy n
LEFT JOIN customer_orders c ON n.n_nationkey = c.c_custkey
LEFT JOIN supplier_parts s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT ep.p_partkey FROM extreme_part ep) LIMIT 1)
LEFT JOIN extreme_part ep ON ep.p_partkey = SOME(SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE (c.total_spent IS NOT NULL OR s.total_supply_cost IS NOT NULL)
AND (n.n_regionkey IS NOT NULL OR n.n_name LIKE '%South%')
ORDER BY n.n_name, total_spent DESC;
