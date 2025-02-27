WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(100)) AS full_name,
           1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CAST(CONCAT(sh.full_name, ' -> ', s.s_name) AS VARCHAR(100)) AS full_name,
           level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_size > 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING total_spent > 100000
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
MergedData AS (
    SELECT ch.c_custkey, ch.c_name, sh.s_name, sh.s_acctbal, 
           rp.p_name, rp.p_retailprice,
           CASE 
               WHEN sh.level IS NULL THEN 'No Hierarchy'
               ELSE sh.level::text
           END AS supplier_level
    FROM CustomerOrders ch
    FULL OUTER JOIN SupplierHierarchy sh ON ch.c_nationkey = sh.s_nationkey
    LEFT JOIN RankedParts rp ON rp.price_rank <= 3
)

SELECT m.c_custkey, m.c_name, m.s_name, m.s_acctbal, 
       m.p_name, m.p_retailprice, m.supplier_level,
       COALESCE(m.supplier_level, 'No Suppliers') AS result_description
FROM MergedData m
WHERE (m.s_acctbal IS NOT NULL AND m.s_acctbal > 10000)
  OR (m.p_retailprice IS NOT NULL AND m.p_retailprice > 500)
ORDER BY m.c_custkey, m.s_name, m.p_retailprice DESC;
