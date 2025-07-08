WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 10000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_nationkey = ch.c_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 10000
),

supplier_part_data AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, ps.ps_partkey
),

ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' 
      AND o.o_orderdate < '1997-10-01'
),

total_sales_per_part AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-10-01'
    GROUP BY l.l_partkey
)

SELECT p.p_partkey, p.p_name, ps.total_availqty, ts.total_sales, 
       CASE 
           WHEN ts.total_sales IS NULL THEN 'No Sales'
           WHEN ts.total_sales > 100000 THEN 'High Demand'
           ELSE 'Regular Demand' 
       END AS sales_category
FROM part p
LEFT JOIN supplier_part_data ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN total_sales_per_part ts ON p.p_partkey = ts.l_partkey
LEFT JOIN customer_hierarchy ch ON ch.c_custkey = ps.s_suppkey
WHERE (ps.total_availqty IS NOT NULL OR ts.total_sales IS NOT NULL)
  AND (p.p_retailprice BETWEEN 10.00 AND 500.00 OR p.p_type LIKE '%Mechanical%')
ORDER BY p.p_partkey
FETCH FIRST 100 ROWS ONLY;