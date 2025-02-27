WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name LIKE 'N%'
    
    UNION ALL
    
    SELECT s.s_suppkey, CONCAT(sh.s_name, ' -> ', s.s_name), sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderstatus, ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
    AND o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
),
EligibleParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p 
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice < 100.00
    GROUP BY p.p_partkey
    HAVING SUM(ps.ps_availqty) > 50
)
SELECT 
    oh.o_orderkey,
    oh.o_totalprice,
    oh.o_orderstatus,
    sp.s_name,
    pp.p_name,
    pp.total_available,
    CASE 
        WHEN oh.o_orderstatus = 'F' THEN 'Finished'
        WHEN oh.o_orderstatus = 'P' THEN 'Pending'
        ELSE 'Unknown'
    END AS order_status_description
FROM FilteredOrders oh
LEFT JOIN lineitem li ON oh.o_orderkey = li.l_orderkey
LEFT JOIN EligibleParts pp ON li.l_partkey = pp.p_partkey
FULL OUTER JOIN SupplierHierarchy sh ON sh.s_suppkey = li.l_suppkey
WHERE pp.total_available IS NOT NULL
AND (sh.level > 0 OR sh.s_name IS NULL)
ORDER BY oh.o_orderkey, pp.total_available DESC
LIMIT 10 OFFSET (SELECT COUNT(*) FROM orders) / 100

