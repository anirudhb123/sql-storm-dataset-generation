WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 30000 AND sh.level < 5
),
ranked_lineitems AS (
    SELECT l.*, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn,
           SUM(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey) AS order_total
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
),
customer_order_summary AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal < 20000
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
)
SELECT r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(cus.total_spent) AS avg_spent_per_customer,
       MAX(pl.p_retailprice) AS max_price,
       MIN(pl.p_retailprice) AS min_price,
       AVG(pl.p_retailprice) AS avg_price,
       SUM(l.l_quantity) AS total_quantity,
       SUM(l.l_extendedprice) AS total_extended_price
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN part pl ON ps.ps_partkey = pl.p_partkey
LEFT JOIN customer_order_summary cus ON cus.c_custkey = ps.ps_suppkey
LEFT JOIN ranked_lineitems l ON l.l_partkey = pl.p_partkey
WHERE l.rn = 1
AND pl.p_size > 10
AND (l.l_discount < 0.1 OR l.l_tax IS NULL)
GROUP BY r.r_name
ORDER BY avg_price DESC
LIMIT 10;
