WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           SUM(o.o_totalprice) AS total_spent, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 0
),
PartSupplier AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_availqty) AS total_available_qty,
           COUNT(DISTINCT ps.ps_suppkey) AS suppliers_count
    FROM part p 
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CriticalOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           MAX(li.l_extendedprice * (1 - li.l_discount)) AS max_order_value, 
           COUNT(li.l_orderkey) AS total_line_items
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT C.c_name, 
       COALESCE(REGEXP_REPLACE(SUBSTRING_INDEX(N.r_comment, ' ', 3), '[[:cntrl:]]', ''), 'Unknown') AS region_comment,
       P.p_name,
       PS.total_available_qty,
       CASE 
           WHEN Coalesce(C.total_spent, 0) > 10000 THEN 'High Value Customer'
           WHEN Coalesce(C.total_spent, 0) BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_value,
       SUM(CASE 
           WHEN o.o_orderstatus = 'F' THEN 1 
           ELSE 0 
       END) AS fulfilled_order_count
FROM CustomerSummary C
JOIN CriticalOrders o ON C.order_count = o.total_line_items
LEFT OUTER JOIN region R ON C.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = R.r_regionkey)
JOIN PartSupplier PS ON PS.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
GROUP BY C.c_name, R.r_comment, P.p_name, PS.total_available_qty
ORDER BY P.p_name ASC, customer_value DESC
LIMIT 100;
