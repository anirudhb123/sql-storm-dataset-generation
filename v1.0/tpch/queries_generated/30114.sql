WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000
),
high_value_orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount < 0.2
    GROUP BY o.o_orderkey
    HAVING total_value > 10000
),
ranked_lineitems AS (
    SELECT ll.l_orderkey, ll.l_partkey, ll.l_suppkey, ll.l_quantity, ll.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY ll.l_orderkey ORDER BY ll.l_extendedprice DESC) AS rank
    FROM lineitem ll
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT DISTINCT sd.s_name, sd.nation_name, sh.level,
       (CASE WHEN hvo.total_value IS NOT NULL THEN hvo.total_value ELSE 0 END) AS order_value,
       COUNT(DISTINCT CASE WHEN rl.rank <= 5 THEN rl.l_partkey END) AS top_lineitems_count
FROM supplier_details sd
LEFT JOIN high_value_orders hvo ON sd.s_suppkey = hvo.o_orderkey
LEFT JOIN ranked_lineitems rl ON sd.s_suppkey = rl.l_suppkey
LEFT JOIN supplier_hierarchy sh ON sd.s_suppkey = sh.s_suppkey
WHERE sd.s_name IS NOT NULL
AND (sd.nation_name IS NOT NULL OR sd.region_name IS NOT NULL)
ORDER BY sd.nation_name, order_value DESC;
