WITH RECURSIVE top_nations AS (
    SELECT n_nationkey, n_name, n_regionkey,
           ROW_NUMBER() OVER (PARTITION BY n_regionkey ORDER BY n_nationkey) AS rn
    FROM nation
),
high_value_suppliers AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) * 1.10 FROM supplier
    )
), 
part_supp_costs AS (
    SELECT ps.partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN high_value_suppliers hs ON ps.ps_suppkey = hs.s_suppkey
    GROUP BY ps.partkey
),
lineitem_details AS (
    SELECT l.*, 
           CASE 
               WHEN l_returnflag = 'R' THEN l_extendedprice * (1 - l_discount) * (1 + l_tax)
               ELSE NULL
           END AS net_revenue
    FROM lineitem l
)
SELECT COALESCE(r.r_name, 'Unknown Region') AS region_name,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(ld.net_revenue) AS total_net_revenue,
       AVG(pc.total_supplycost) AS avg_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem_details ld ON o.o_orderkey = ld.l_orderkey
LEFT JOIN part_supp_costs pc ON ld.l_partkey = pc.partkey
WHERE r.r_name IS NOT NULL AND ld.l_shipdate BETWEEN '2022-01-01' AND '2023-01-01'
GROUP BY r.r_regionkey, r.r_name, n.n_nationkey
HAVING COUNT(DISTINCT c.c_custkey) > 
       (SELECT COUNT(*) / 10 FROM customer WHERE c_acctbal IS NOT NULL)
ORDER BY region_name DESC;
