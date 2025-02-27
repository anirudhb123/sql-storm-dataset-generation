WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice, p_comment, 1 AS level
    FROM part
    WHERE p_size < 50
    
    UNION ALL
    
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice * 0.9 AS adjusted_price, 
           CONCAT(ph.p_comment, ' | Variant of: ', p.p_name) AS p_comment, 
           level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey + 1
    WHERE level < 3
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, 
           COUNT(DISTINCT ps.ps_partkey) AS total_parts,
           SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderSum AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_orders_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY c.c_custkey, c.c_name
),
FinalResults AS (
    SELECT p.p_name, p.adjusted_price, ss.total_parts, 
           cos.total_orders_value,
           CASE 
               WHEN cos.total_orders_value IS NULL THEN 'No Orders'
               ELSE 'Orders Present'
           END AS order_status
    FROM PartHierarchy p
    LEFT JOIN SupplierStats ss ON p.p_partkey = ss.s_suppkey
    LEFT JOIN CustomerOrderSum cos ON ss.total_parts = cos.c_custkey
    WHERE p.p_retailprice > 100 
      AND ss.total_supplycost IS NOT NULL
)
SELECT p_name, adjusted_price, total_parts, total_orders_value, order_status
FROM FinalResults
WHERE total_parts > 0 
ORDER BY adjusted_price DESC, total_orders_value ASC
LIMIT 10;
