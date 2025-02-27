WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 
           s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal AND sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
),
PartUsage AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice) AS avg_price, 
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_quantity) DESC) AS usage_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '1 YEAR'
    GROUP BY p.p_partkey, p.p_name
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, pu.total_quantity, pu.avg_price
    FROM part_usage pu
    JOIN part p ON pu.p_partkey = p.p_partkey
    WHERE pu.usage_rank <= 10
)
SELECT c.c_name AS customer_name, 
       COALESCE(SUM(co.o_totalprice), 0) AS total_orders,
       COALESCE(SUM(tp.total_quantity), 0) AS total_part_quantity,
       COALESCE(AVG(tp.avg_price), 0) AS avg_part_price,
       sh.level AS supplier_level
FROM CustomerOrders co
FULL OUTER JOIN TopParts tp ON tp.p_partkey = 
    (SELECT DISTINCT l.l_partkey 
     FROM lineitem l 
     WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey))
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = co.o_orderkey
GROUP BY c.c_name, sh.level
HAVING total_orders > 100 OR total_part_quantity > 50
ORDER BY customer_name;
