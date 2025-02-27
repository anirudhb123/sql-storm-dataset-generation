WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_nationkey, 0 AS level
    FROM customer
    WHERE c_nationkey IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE ch.level < 5
),
EligibleSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, ps.ps_comment
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)

SELECT 
    ch.c_name AS Customer_Name,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS Total_Sales,
    AVG(li.l_tax) AS Average_Tax,
    COUNT(DISTINCT es.s_suppkey) AS Eligible_Suppliers_Count,
    STRING_AGG(DISTINCT es.s_name, ', ') AS Eligible_Suppliers
FROM CustomerHierarchy ch
LEFT JOIN orders o ON ch.c_custkey = o.o_custkey
LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
LEFT JOIN EligibleSuppliers es ON li.l_suppkey = es.s_suppkey
GROUP BY ch.c_name
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 5000
ORDER BY Total_Sales DESC
LIMIT 10;
