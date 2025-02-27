WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_item_count,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
DistinctParts AS (
    SELECT DISTINCT p.p_partkey, p.p_name, p.p_retailprice
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_supplycost IS NOT NULL
)
SELECT 
    sh.s_name AS supplier_name,
    oh.o_orderkey,
    od.total_price,
    od.line_item_count,
    dp.p_name AS part_name,
    dp.p_retailprice,
    sh.level,
    CASE 
        WHEN od.total_price IS NULL THEN 'No Orders'
        ELSE 'Has Orders' 
    END AS order_status
FROM SupplierHierarchy sh
FULL OUTER JOIN OrderDetails od ON sh.s_suppkey = od.o_orderkey
JOIN DistinctParts dp ON dp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(ps_supplycost) FROM partsupp) LIMIT 1)
WHERE (sh.level IS NOT NULL OR od.o_orderkey IS NOT NULL)
ORDER BY sh.level, od.total_price DESC;
