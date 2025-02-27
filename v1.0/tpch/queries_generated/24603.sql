WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           CASE 
               WHEN p.p_retailprice >= 1000 THEN 'High'
               WHEN p.p_retailprice >= 500 THEN 'Medium'
               ELSE 'Low'
           END AS price_category
    FROM part p
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' 
          AND o.o_orderstatus IN ('F', 'O')
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT r.s_name, r.s_acctbal, 
       hp.p_name, hp.price_category, 
       fo.total_lineitem_value, 
       CASE 
           WHEN fo.lineitem_count > 5 THEN 'Bulk'
           ELSE 'Single'
       END AS order_type,
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       AVG(fo.total_lineitem_value) OVER (PARTITION BY hp.price_category) AS avg_value_by_category
FROM RankedSuppliers r
LEFT JOIN partsupp ps ON r.s_suppkey = ps.ps_suppkey
LEFT JOIN HighValueParts hp ON ps.ps_partkey = hp.p_partkey
JOIN FilteredOrders fo ON fo.o_orderkey = ps.ps_partkey
JOIN nation n ON r.s_nationkey = n.n_nationkey
WHERE r.rnk <= 3
  AND (hp.price_category = 'High' OR hp.price_category IS NULL)
GROUP BY r.s_name, r.s_acctbal, hp.p_name, hp.price_category, fo.total_lineitem_value
HAVING SUM(CASE WHEN hp.p_retailprice IS NULL THEN 1 ELSE 0 END) = 0
ORDER BY avg_value_by_category DESC, r.s_acctbal ASC;
