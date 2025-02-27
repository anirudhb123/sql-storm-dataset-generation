WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS level
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey + 1
    WHERE ch.level < 5
), 
FilteredPart AS (
    SELECT p.p_partkey, p.p_name, 
           CASE 
               WHEN p.p_retailprice IS NULL THEN 0 
               ELSE ROUND(p.p_retailprice * 1.05, 2) 
           END AS adjusted_price
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 10
    AND p.p_comment NOT LIKE '%obsolete%'
), 
SupplierStats AS (
    SELECT s.s_nationkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM supplier s 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
), 
MaxPrices AS (
    SELECT MAX(adjusted_price) AS max_price_per_part,
           COUNT(DISTINCT p.p_partkey) AS unique_parts_count
    FROM FilteredPart p
)
SELECT coalesce(s.n_name, 'Unknown') AS nation_name,
       cs.c_name AS customer_name,
       l.l_shipmode,
       p.p_name,
       l.l_quantity,
       MAX(p.adjusted_price) OVER (PARTITION BY l.l_shipmode ORDER BY l.l_shipdate DESC) AS max_shipmode_price,
       CASE 
           WHEN MAX(su.total_supply_cost) IS NULL THEN 'No Suppliers' 
           ELSE 'Suppliers Available' 
       END AS supplier_status,
       ch.level AS customer_level
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer cs ON o.o_custkey = cs.c_custkey
LEFT JOIN nation s ON cs.c_nationkey = s.n_nationkey
LEFT JOIN FilteredPart p ON l.l_partkey = p.p_partkey
LEFT JOIN SupplierStats su ON s.s_nationkey = su.s_nationkey
JOIN MaxPrices mp ON 1=1
LEFT JOIN CustomerHierarchy ch ON cs.c_custkey = ch.c_custkey
WHERE l.l_discount > (SELECT AVG(l_discount) FROM lineitem WHERE l_quantity < 10)
  AND l.l_returnflag = 'N'
ORDER BY nation_name, customer_name, l.l_shipdate DESC
FETCH FIRST 100 ROWS ONLY;
