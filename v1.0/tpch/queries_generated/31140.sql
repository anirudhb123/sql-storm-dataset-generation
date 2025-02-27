WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
order_summary AS (
    SELECT lo.l_orderkey, COUNT(DISTINCT lo.l_partkey) AS num_items,
           SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM lineitem lo
    INNER JOIN high_value_orders ho ON lo.l_orderkey = ho.o_orderkey
    GROUP BY lo.l_orderkey
    HAVING SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 10000
),
nation_info AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name,
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN partsupp ps ON n.n_nationkey = (
        SELECT DISTINCT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey
    )
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT nh.n_name, nh.region_name, COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
       SUM(os.total_revenue) AS total_revenue, AVG(os.num_items) AS avg_items_per_order,
       MAX(nh.total_supply_cost) AS highest_supply_cost
FROM nation_info nh
JOIN supplier_hierarchy sh ON nh.n_nationkey = sh.s_nationkey
JOIN order_summary os ON sh.s_suppkey = (
    SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = os.l_orderkey
    )
)
WHERE nh.total_supply_cost IS NOT NULL
GROUP BY nh.n_name, nh.region_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 5
ORDER BY highest_supply_cost DESC;
