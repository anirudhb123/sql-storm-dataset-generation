WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_retailprice, 
           1 AS level, NULL::integer AS parent_partkey
    FROM part
    WHERE p_size > 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size,
           p.p_retailprice, ph.level + 1, ph.p_partkey
    FROM part p
    JOIN part_hierarchy ph ON p.p_size < ph.p_size AND ph.level < 5
),
customer_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
supplier_availability AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT s.s_suppkey, s.s_name, sa.total_available, 
       COALESCE(cs.total_spent, 0) AS total_spent, 
       CASE 
           WHEN sa.total_available IS NULL THEN 'No Supply' 
           WHEN sa.unique_suppliers > 5 THEN 'Well Supported' 
           ELSE 'Limited Support' 
       END AS support_level,
       (SELECT COUNT(DISTINCT l.l_orderkey) 
        FROM lineitem l 
        WHERE l.l_suppkey = s.s_suppkey 
          AND l.l_discount > 0.1) AS order_discount_count,
       PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY distinct_part_prices) 
           OVER (PARTITION BY sa.ps_partkey) AS median_price
FROM supplier s
LEFT JOIN supplier_availability sa ON s.s_suppkey = sa.ps_supkey
LEFT JOIN customer_summary cs ON cs.c_custkey IN (
    SELECT o.o_custkey
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'R' AND l.l_shipdate < CURRENT_DATE
)
WHERE s.s_acctbal IS NOT NULL
AND (s.s_comment IS NULL OR LENGTH(s.s_comment) > 10)
ORDER BY support_level DESC, total_spent DESC
FETCH FIRST 100 ROWS ONLY;
