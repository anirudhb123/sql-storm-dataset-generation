WITH RECURSIVE region_cycle AS (
    SELECT r_regionkey, r_name, r_comment, 1 AS level
    FROM region
    WHERE r_name LIKE '%North%'
    
    UNION ALL
    
    SELECT r.regionkey, r.name, r.comment, rc.level + 1
    FROM region r
    JOIN region_cycle rc ON r.regionkey = (rc.level % 4) + 1
    WHERE rc.level < 10
),
supplier_summary AS (
    SELECT s.nationkey, 
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(s.s_acctbal) AS total_balance,
           MAX(s.s_acctbal) AS max_balance,
           MIN(s.s_acctbal) AS min_balance
    FROM supplier s
    GROUP BY s.nationkey
),
lineitem_stats AS (
    SELECT l.l_orderkey,
           AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns,
           COUNT(*) AS line_count
    FROM lineitem l
    GROUP BY l.l_orderkey
),
customer_avg_balance AS (
    SELECT c.c_nationkey,
           AVG(c.c_acctbal) AS avg_balance
    FROM customer c
    GROUP BY c.c_nationkey
)

SELECT coalesce(r.r_name, 'Unknown Region') AS region_name, 
       ss.total_suppliers,
       ss.total_balance,
       ss.max_balance,
       ss.min_balance,
       la.avg_price,
       la.returns,
       la.line_count,
       cab.avg_balance
FROM region_cycle r
FULL OUTER JOIN supplier_summary ss ON ss.nationkey = r.r_regionkey
FULL OUTER JOIN lineitem_stats la ON la.l_orderkey = ss.total_suppliers
FULL OUTER JOIN customer_avg_balance cab ON cab.c_nationkey = ss.nationkey
WHERE (ss.total_balance IS NULL OR ss.total_balance > 5000) 
  AND (la.returns > 0 OR la.line_count < 5)
  AND EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey = ss.nationkey AND s.s_acctbal IS NOT NULL)
ORDER BY r.r_name DESC NULLS LAST, ss.max_balance ASC;
