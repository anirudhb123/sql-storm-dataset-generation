WITH region_summary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count, SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
customer_order_summary AS (
    SELECT c.c_nationkey, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
),
supply_part_summary AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT
    rs.r_name,
    rs.nation_count,
    rs.total_acctbal,
    cos.order_count,
    cos.total_order_value,
    sps.total_availqty,
    sps.avg_supplycost
FROM region_summary rs
LEFT JOIN customer_order_summary cos ON cos.c_nationkey = (SELECT n.n_nationkey FROM nation n JOIN region r ON n.n_regionkey = r.r_regionkey WHERE r.r_name = rs.r_name LIMIT 1)
LEFT JOIN supply_part_summary sps ON sps.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = rs.r_name LIMIT 1)) LIMIT 1)
ORDER BY rs.r_name;
