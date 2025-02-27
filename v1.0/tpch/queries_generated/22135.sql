WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal * 1.1, level + 1
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_suppkey = cte.s_suppkey
    WHERE level < 3
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_availqty,
           SUM(ps.ps_supplycost * COALESCE(NULLIF(p.p_retailprice, 0), 1)) AS total_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
MaxCost AS (
    SELECT MAX(total_cost) AS max_cost
    FROM PartDetails
),
QualifiedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, p.p_partkey, p.p_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) AND p.p_retailprice < (SELECT max_cost FROM MaxCost)
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
)
SELECT 
    s.s_suppkey, s.s_name, 
    COUNT(DISTINCT q.p_partkey) AS num_parts,
    SUM(o.o_totalprice) AS total_order_amount,
    AVG(o.o_totalprice) AS avg_order_amount,
    CASE 
        WHEN COUNT(DISTINCT q.p_partkey) > 5 THEN 'High Supplier Engagement'
        ELSE 'Low Supplier Engagement'
    END AS engagement_level,
    ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS supplier_rank
FROM QualifiedSuppliers q
JOIN orders o ON q.s_suppkey = o.o_custkey
RIGHT JOIN supplier s ON q.s_suppkey = s.s_suppkey OR q.s_suppkey IS NULL
WHERE o.o_orderstatus IN ('O', 'F')
GROUP BY s.s_suppkey, s.s_name
HAVING SUM(o.o_totalprice) > 1000 OR MIN(o.o_totalprice) IS NULL
ORDER BY engagement_level, total_order_amount DESC;
