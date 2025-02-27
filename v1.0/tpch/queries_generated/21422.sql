WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL AND s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal * 0.9, h.level + 1
    FROM supplier s
    JOIN SupplierHierarchy h ON s.s_nationkey = h.s_nationkey
    WHERE h.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 500 
      AND (c.c_mktsegment IN ('BUILDING', 'HOUSEHOLD') 
           OR c.c_name LIKE '%Corp%')
    GROUP BY c.c_custkey, c.c_name
),
DistinctParts AS (
    SELECT DISTINCT p.p_partkey, p.p_name, 
           CASE 
               WHEN p.p_retailprice > 100 THEN 'Expensive' 
               WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
               ELSE 'Cheap' 
           END AS price_category
    FROM part p
    WHERE p.p_comment IS NULL 
      OR p.p_size IS NOT NULL
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey,
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_discount DESC) AS discount_rank
    FROM lineitem l
    WHERE l.l_discount IS NOT NULL AND l.l_returnflag = 'N'
)
SELECT ch.c_custkey, ch.c_name, 
       SUM(COALESCE(lp.l_extendedprice, 0)) AS total_extended_price,
       SUM(COALESCE(sp.s_acctbal, 0)) AS total_supplier_balance,
       STRING_AGG(DISTINCT dp.price_category, ', ') AS unique_price_categories
FROM CustomerOrders ch
LEFT JOIN RankedLineItems lp ON ch.order_count > 0 
    AND EXISTS (SELECT 1 FROM lineitem l 
                WHERE l.l_orderkey = lp.l_orderkey 
                  AND l.l_partkey = dp.p_partkey)
FULL OUTER JOIN SupplierHierarchy sp ON ch.custkey = sp.s_suppkey
FULL OUTER JOIN DistinctParts dp ON dp.p_partkey = lp.l_partkey
WHERE ch.order_count >= 2
GROUP BY ch.c_custkey, ch.c_name
HAVING SUM(COALESCE(lp.l_discount, 0)) < 10
ORDER BY total_extended_price DESC NULLS LAST;
