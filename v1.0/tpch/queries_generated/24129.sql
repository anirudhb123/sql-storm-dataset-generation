WITH RECURSIVE region_nation AS (
    SELECT r_regionkey, r_name, r_comment, n_nationkey
    FROM region
    JOIN nation ON r_regionkey = n_regionkey
), 
supplier_summary AS (
    SELECT s_nationkey, AVG(s_acctbal) AS avg_acctbal, COUNT(*) AS supplier_count
    FROM supplier
    GROUP BY s_nationkey
), 
parts_with_prices AS (
    SELECT p_partkey, p_name, p_retailprice, ps_supplycost, 
           CASE 
               WHEN ps_supplycost IS NULL THEN 0
               WHEN p_retailprice > ps_supplycost THEN p_retailprice - ps_supplycost
               ELSE -1 * (ps_supplycost - p_retailprice)
           END AS price_difference
    FROM part
    LEFT JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
), 
order_summary AS (
    SELECT o_custkey, 
           SUM(o_totalprice) AS total_spent, 
           COUNT(o_orderkey) AS order_count,
           RANK() OVER (PARTITION BY o_custkey ORDER BY SUM(o_totalprice) DESC) AS spending_rank
    FROM orders
    GROUP BY o_custkey
) 
SELECT r.r_name AS region_name, 
       n.n_name AS nation_name, 
       AVG(ps.avg_acctbal) AS avg_supplier_acctbal,
       COUNT(DISTINCT pa.p_partkey) AS part_count,
       MAX(pa.price_difference) AS max_price_diff,
       COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderstatus = 'F') AS completed_orders,
       SUM(CASE WHEN n.n_name IS NULL THEN 1 ELSE 0 END) AS null_nation_count
FROM region_nation r
JOIN supplier_summary ps ON r.n_nationkey = ps.s_nationkey
LEFT JOIN parts_with_prices pa ON ps.s_nationkey = pa.p_partkey
FULL OUTER JOIN order_summary o ON r.n_nationkey = o.o_custkey
WHERE (pa.price_difference IS NOT NULL OR o.total_spent > 1000)
GROUP BY r.r_name, n.n_name
HAVING AVG(ps.avg_acctbal) > (SELECT AVG(s_acctbal) FROM supplier)
   OR COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY region_name DESC, nation_name;
