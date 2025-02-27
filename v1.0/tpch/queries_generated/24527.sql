WITH RECURSIVE price_trend AS (
    SELECT p_partkey, p_name, p_retailprice, p_size,
           ROW_NUMBER() OVER (PARTITION BY p_partkey ORDER BY p_retailprice DESC) AS rank
    FROM part
    WHERE p_retailprice IS NOT NULL
), price_summaries AS (
    SELECT p_partkey, COUNT(*) AS price_changes, 
           AVG(p_retailprice) AS avg_price,
           MAX(p_retailprice) AS max_price,
           MIN(p_retailprice) AS min_price
    FROM price_trend
    GROUP BY p_partkey
), eligible_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment,
           COUNT(DISTINCT ps.ps_partkey) AS supply_count
    FROM supplier s
    LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier 
        WHERE s_comment IS NOT NULL
    ) OR s.s_name LIKE '%Inc%'
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
), order_summary AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice,
           SUM(l.l_discount) AS total_discount
    FROM orders o
    LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice
)
SELECT e.s_suppkey, e.s_name, e.s_acctbal, os.o_orderkey, 
       os.o_totalprice, ps.max_price, ps.avg_price,
       CASE 
           WHEN ps.price_changes = 1 THEN 'Stable'
           WHEN ps.price_changes > 1 THEN 'Volatile'
           ELSE 'Unknown'
       END AS price_volatility
FROM eligible_suppliers e
JOIN price_summaries ps ON e.s_supply_count > 5
FULL OUTER JOIN order_summary os ON os.o_totalprice > ps.avg_price
WHERE (e.s_acctbal IS NOT NULL AND e.s_comment IS NOT NULL)
   OR (e.s_acctbal IS NULL AND e.s_name LIKE 'A%')
ORDER BY e.s_acctbal DESC NULLS LAST, ps.max_price ASC, os.o_totalprice DESC;
