WITH RECURSIVE nation_tree AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS depth
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nt.depth + 1
    FROM nation n
    INNER JOIN nation_tree nt ON n.n_regionkey = nt.n_nationkey
),
ranked_orders AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           o.o_orderdate,
           DENSE_RANK() OVER(PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
supplier_part_summary AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS average_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey
)
SELECT n.n_name AS nation_name,
       COUNT(DISTINCT c.c_custkey) AS total_customers,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COALESCE(SUM(sps.total_available), 0) AS total_avail_qty,
       MAX(sps.average_cost) AS max_supply_cost,
       RANK() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN supplier_part_summary sps ON l.l_partkey = sps.ps_partkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
WHERE l.l_shipdate >= '2022-01-01'
  AND l.l_shipdate < '2023-01-01'
  AND l.l_returnflag = 'N'
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_revenue DESC
LIMIT 10;
