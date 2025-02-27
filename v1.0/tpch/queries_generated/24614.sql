WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier 
    WHERE s_name LIKE 'S%'
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
), 

PartJoin AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           p.p_retailprice * COALESCE(NULLIF(ps.ps_availqty, 0), 1) AS p_value,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
), 

OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, COUNT(l.l_orderkey) AS lineitem_count,
           SUM(l.l_quantity * l.l_extendedprice) AS total_lineitem_value
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND CURRENT_DATE
    GROUP BY o.o_orderkey, o.o_orderstatus
)

SELECT 
    p.p_name, p.p_brand, 
    (Ph.s_name IS NOT NULL AND p_value > 1000) AS expensive_parts,
    od.lineitem_count,
    SUM(CASE WHEN od.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS finished_orders,
    AVG(Ph.s_acctbal) AS avg_supplier_balance
FROM PartJoin p
FULL OUTER JOIN SupplierHierarchy Ph ON p.p_partkey = Ph.s_suppkey
LEFT JOIN OrderDetails od ON od.o_orderkey = (SELECT MAX(o.o_orderkey) 
                                                FROM orders o
                                                WHERE o.o_orderkey < 99999)
WHERE p.rn = 1 AND (p_value IS NOT NULL OR Ph.s_suppkey IS NULL)
GROUP BY p.p_name, p.p_brand, od.lineitem_count, Ph.s_name
HAVING COUNT(DISTINCT Ph.s_name) > 1
ORDER BY avg_supplier_balance DESC NULLS LAST;
