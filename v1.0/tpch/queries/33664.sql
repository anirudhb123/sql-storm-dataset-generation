WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 5000 AND sh.level < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > (
        SELECT AVG(o2.o_totalprice)
        FROM orders o2
        WHERE o2.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    )
),
PartSupplierStats AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
)
SELECT 
    sh.s_name AS Supplier_Name, 
    co.c_name AS Customer_Name, 
    cos.total_cost,
    CASE 
        WHEN sh.level = 0 THEN 'High Value'
        ELSE 'Medium Value'
    END AS Account_Level,
    COUNT(co.o_orderkey) AS Order_Count
FROM SupplierHierarchy sh
JOIN CustomerOrders co ON sh.s_nationkey = co.c_custkey
JOIN PartSupplierStats cos ON cos.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = co.o_orderkey LIMIT 1)
GROUP BY sh.s_name, co.c_name, cos.total_cost, sh.level
ORDER BY total_cost DESC, Order_Count DESC;