WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
TotalOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_custkey) AS total_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
SupplierAvgCost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopSuppliers AS (
    SELECT s.s_name, s.s_acctbal, COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING COUNT(DISTINCT ps.ps_partkey) > 3
),
RankedParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
)
SELECT 
    r.r_name AS region, 
    n.n_name AS nation, 
    s.s_name AS supplier_name, 
    SUM(t.total_sales) AS total_sales,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    MIN(sa.avg_supplycost) AS min_avg_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(MAX(sh.level), 0) AS supplier_level
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN TotalOrders t ON s.s_suppkey = t.o_orderkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN SupplierAvgCost sa ON ps.ps_partkey = sa.ps_partkey
LEFT JOIN RankedParts p ON ps.ps_partkey = p.p_partkey
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
WHERE r.r_name LIKE 'N%' AND (s.s_acctbal IS NOT NULL OR s.s_comment IS NOT NULL)
GROUP BY r.r_name, n.n_name, s.s_name
HAVING SUM(t.total_sales) > 10000
ORDER BY total_sales DESC;
