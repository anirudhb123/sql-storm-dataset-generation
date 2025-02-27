WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > 1000
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
),
FinalOutput AS (
    SELECT th.s_name AS supplier_name, co.c_name AS customer_name, li.l_extendedprice AS price,
           CASE WHEN li.price_rank = 1 THEN 'Highest Price' ELSE 'Regular' END AS price_rank_status
    FROM TopSuppliers th
    JOIN CustomerOrders co ON co.c_custkey = (SELECT MIN(c_custkey) FROM customer ORDER BY c_acctbal DESC LIMIT 1)
    FULL OUTER JOIN RankedLineItems li ON li.l_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o)
)
SELECT DISTINCT supplier_name, customer_name, price, price_rank_status
FROM FinalOutput
WHERE customer_name IS NOT NULL 
AND supplier_name IS NOT NULL
ORDER BY price DESC, supplier_name;
