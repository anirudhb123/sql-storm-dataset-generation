WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    ORDER BY total_supply_cost DESC
    LIMIT 5
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT 
    sh.s_name AS Supplier_Name,
    sh.level AS Supplier_Level,
    tp.p_name AS Top_Part_Name,
    os.o_orderkey AS Order_Key,
    os.revenue AS Order_Revenue
FROM SupplierHierarchy sh
FULL OUTER JOIN TopParts tp ON tp.total_supply_cost > sh.s_acctbal
LEFT JOIN OrderStats os ON os.o_orderkey % 10 = sh.s_suppkey % 10
WHERE (sh.level IS NOT NULL AND tp.p_name IS NOT NULL) OR os.o_orderkey IS NULL
ORDER BY sh.level DESC, tp.total_supply_cost DESC;
