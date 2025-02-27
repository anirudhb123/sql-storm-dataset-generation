WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_agg AS (
    SELECT s_nationkey, COUNT(*) AS supply_count, SUM(s_acctbal) AS total_acctbal
    FROM supplier
    GROUP BY s_nationkey
),
part_retail AS (
    SELECT p_partkey, p_name, p_size, p_retailprice, p_brand,
           ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rank
    FROM part
    WHERE p_retailprice > 100.00
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
)
SELECT r.r_name, n.n_name, p.p_brand, sa.supply_count, sa.total_acctbal,
       os.total_revenue, os.lineitem_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_agg sa ON n.n_nationkey = sa.s_nationkey
LEFT JOIN part_retail p ON p.p_size BETWEEN 10 AND 20
LEFT JOIN order_summary os ON os.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
)
WHERE p.rank <= 5
  AND sa.supply_count IS NOT NULL
  AND os.total_revenue IS NOT NULL
ORDER BY r.r_name, n.n_name, p.p_brand;
