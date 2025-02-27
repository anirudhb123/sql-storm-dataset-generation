WITH ranked_parts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
), 
supplier_info AS (
    SELECT s.s_suppkey,
           s.s_name,
           COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
           STRING_AGG(DISTINCT CONCAT(s.s_name, ' - ', s.s_acctbal), '; ') AS supplier_details
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 500.00
)
SELECT r.r_name,
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns,
       AVG(pr.p_retailprice) AS average_retail_price,
       MIN(pr.p_retailprice) FILTER (WHERE pr.price_rank <= 5) AS min_top5_price,
       MAX(pr.p_retailprice) FILTER (WHERE pr.price_rank <= 5) AS max_top5_price,
       STRING_AGG(DISTINCT sf.supplier_details, ', ') AS multi_supplier_info
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN ranked_parts pr ON pr.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty >= 10)
LEFT JOIN lineitem li ON li.l_partkey = pr.p_partkey
LEFT JOIN supplier_info sf ON sf.total_avail_qty < (SELECT AVG(ps.ps_availqty) FROM partsupp ps)
JOIN customer_orders co ON co.total_orders > 5
GROUP BY r.r_name
HAVING COUNT(n.n_nationkey) > 2 AND SUM(CASE WHEN n.n_name LIKE '%land%' THEN 1 ELSE 0 END) > 0
ORDER BY average_retail_price DESC
LIMIT 10 OFFSET 5;
