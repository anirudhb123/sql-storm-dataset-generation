WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.depth + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.depth < 5
),
part_summary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail,
           AVG(ps.ps_supplycost) AS avg_cost, 
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
nation_supplier AS (
    SELECT n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
max_order AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
cumulative_prices AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (ORDER BY o.o_orderkey DESC) AS cumulative_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
)
SELECT 
    nh.n_name, 
    ps.p_name, 
    ps.total_avail, 
    ps.avg_cost, 
    bh.total_acctbal AS nation_acctbal,
    coalesce(cp.cumulative_price, 0) AS total_cumulative_price,
    sh.depth
FROM part_summary ps
INNER JOIN nation_supplier nh ON nh.total_suppliers > 10
LEFT JOIN cumulative_prices cp ON cp.o_orderkey = ps.p_partkey
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = ps.p_partkey
WHERE ps.total_avail IS NOT NULL AND ps.avg_cost < (
      SELECT AVG(avg_cost) FROM part_summary WHERE total_avail > 100
)
ORDER BY nh.n_name, ps.p_name;
