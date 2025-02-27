WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND sh.level < 5
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
),
HighValueSuppliers AS (
    SELECT sh.s_suppkey, AVG(sh.s_acctbal) AS avg_acctbal
    FROM SupplierHierarchy sh
    GROUP BY sh.s_suppkey
    HAVING ROUND(AVG(sh.s_acctbal), 2) > 10000
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, COUNT(l.l_orderkey) AS order_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
    HAVING COUNT(l.l_orderkey) > 10
),
SupplierDiscount AS (
    SELECT ps.ps_partkey, SUM(l.l_discount * l.l_extendedprice) AS total_discount
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE l.l_returnflag = 'R'
    GROUP BY ps.ps_partkey
)
SELECT p.p_partkey, p.p_name, p.p_brand, 
       COALESCE(hv.avg_acctbal, 0) AS average_account_balance,
       COALESCE(sd.total_discount, 0) AS total_discount,
       (p.p_retailprice * 0.8) AS discounted_price,
       CASE 
           WHEN sd.total_discount > 500 THEN 'High Discount'
           ELSE 'Standard Discount'
       END AS discount_category
FROM TopParts p
LEFT JOIN HighValueSuppliers hv ON p.p_partkey = hv.s_suppkey
LEFT JOIN SupplierDiscount sd ON p.p_partkey = sd.ps_partkey
WHERE p.p_retailprice IS NOT NULL 
  AND p.p_brand LIKE '%Brand%'
  AND (sd.total_discount IS NOT NULL OR p.p_partkey IN (SELECT ps_partkey FROM PartSupplier WHERE rn = 1))
ORDER BY discounted_price DESC, average_account_balance ASC;
