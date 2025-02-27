WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount BETWEEN 0.05 AND 0.1 
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
CombinedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        (SELECT AVG(s.s_acctbal) FROM SupplierHierarchy s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')) AS avg_supplier_acctbal,
        COALESCE((SELECT MAX(h.total_value) FROM HighValueOrders h WHERE h.o_orderkey IS NOT NULL), 0) AS max_order_value
    FROM FilteredParts p
)
SELECT 
    cd.p_partkey,
    cd.p_name,
    cd.p_retailprice,
    cd.avg_supplier_acctbal,
    cd.max_order_value,
    CASE
        WHEN cd.p_retailprice < cd.avg_supplier_acctbal THEN 'Below Average'
        WHEN cd.p_retailprice = cd.avg_supplier_acctbal THEN 'Average'
        ELSE 'Above Average'
    END AS price_to_avg_acctbal_ratio,
    ROW_NUMBER() OVER (PARTITION BY CASE WHEN cd.p_retailprice < cd.avg_supplier_acctbal THEN 'Below Average'
                                           WHEN cd.p_retailprice = cd.avg_supplier_acctbal THEN 'Average'
                                           ELSE 'Above Average' END 
                       ORDER BY cd.p_retailprice ASC) AS rank
FROM CombinedData cd
WHERE cd.max_order_value IS NOT NULL OR cd.avg_supplier_acctbal IS NOT NULL
ORDER BY cd.p_retailprice DESC;
