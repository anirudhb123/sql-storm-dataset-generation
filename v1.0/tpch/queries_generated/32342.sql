WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 2
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
part_supplier_available AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, pa.total_available,
           RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank,
           CASE 
               WHEN p.p_retailprice > 100.00 THEN 'High Price'
               WHEN p.p_retailprice BETWEEN 50.00 AND 100.00 THEN 'Medium Price'
               ELSE 'Low Price' 
           END AS price_category
    FROM part p
    JOIN part_supplier_available pa ON p.p_partkey = pa.p_partkey
)
SELECT rh.s_name AS supplier_name, 
       rh.level AS supplier_level, 
       co.c_name AS customer_name, 
       co.total_spent AS customer_spending, 
       rp.p_name AS part_name, 
       rp.price_category,
       COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM supplier_hierarchy rh
JOIN customer_order_summary co ON rh.s_nationkey = co.c_custkey
JOIN lineitem l ON l.l_suppkey = rh.s_suppkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN ranked_parts rp ON l.l_partkey = rp.p_partkey
WHERE o.o_orderstatus = 'O'
GROUP BY rh.s_name, rh.level, co.c_name, co.total_spent, rp.p_name, rp.price_category
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00
ORDER BY rp.price_rank, co.total_spent DESC;
