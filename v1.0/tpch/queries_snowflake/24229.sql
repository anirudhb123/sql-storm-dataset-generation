
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1 WHERE s1.s_nationkey = s.s_nationkey)
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderstatus,
           COUNT(l.l_orderkey) AS item_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           CASE WHEN o.o_orderstatus = 'F' THEN 'Finalized'
                ELSE 'Not Finalized' END AS order_status_description
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
EligibleParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice >= 100.00
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
)
SELECT R.s_suppkey, R.s_name, E.p_partkey, E.p_name, O.o_orderkey, O.total_revenue,
       CASE 
           WHEN O.item_count > 10 THEN 'Large Order'
           WHEN O.item_count BETWEEN 5 AND 10 THEN 'Medium Order'
           ELSE 'Small Order' 
       END AS order_size_category
FROM RankedSuppliers R
FULL OUTER JOIN EligibleParts E ON R.s_suppkey = (
    SELECT s.s_suppkey 
    FROM supplier s 
    WHERE s.s_name LIKE '%' || REPLACE(E.p_name, ' ', '%') || '%'
    LIMIT 1
)
LEFT JOIN OrderStats O ON O.o_orderkey = (
    SELECT o.o_orderkey 
    FROM OrderStats 
    WHERE o_orderstatus = 'F' 
    ORDER BY item_count DESC 
    LIMIT 1
)
WHERE R.rank = 1 AND (O.total_revenue IS NULL OR O.total_revenue > 1000.00)
ORDER BY R.s_suppkey, E.p_partkey;
