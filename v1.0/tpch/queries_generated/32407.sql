WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal
),

ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),

part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS price_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
)

SELECT 
    r.r_name AS region_name, 
    n.n_name AS nation_name, 
    c.c_name AS customer_name, 
    so.o_orderkey, 
    so.price_rank AS order_price_rank, 
    ps.p_name AS part_name, 
    ps.price_rank AS part_price_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN ranked_orders so ON c.c_custkey = so.o_orderkey
LEFT JOIN part_supplier ps ON ps.price_rank = 1
WHERE COALESCE(so.o_orderkey, 0) > 0 
  AND (c.c_acctbal IS NOT NULL AND c.c_acctbal > 500)
ORDER BY region_name, nation_name, customer_name, order_price_rank;
