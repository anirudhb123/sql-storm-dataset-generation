WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'Europe')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_totalprice > 10000
),
large_lineitems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT nh.n_name, s.s_name, s.s_acctbal, h.o_orderkey, h.o_totalprice,
       ll.total_price AS large_lineitem_price
FROM nation_hierarchy nh
LEFT JOIN supplier_details s ON s.s_nationkey = nh.n_nationkey AND s.rn = 1
LEFT JOIN high_value_orders h ON h.o_orderkey IN (
    SELECT DISTINCT l.l_orderkey
    FROM lineitem l
    WHERE l.l_suppkey IN (SELECT ps.s_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_size = 10
    ))
) 
LEFT JOIN large_lineitems ll ON ll.l_orderkey = h.o_orderkey
WHERE s.s_acctbal IS NOT NULL OR ll.total_price IS NOT NULL
ORDER BY nh.n_name, h.o_totalprice DESC;
