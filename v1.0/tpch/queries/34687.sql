WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
PartDetail AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           ROW_NUMBER() OVER(PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
),
HighSpendingCustomers AS (
    SELECT cust.c_custkey, cust.c_name
    FROM CustomerOrders cust
    WHERE cust.total_spent > (
        SELECT AVG(total_spent) FROM CustomerOrders
    )
)

SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    s.s_name AS supplier_name
FROM lineitem l
JOIN PartDetail p ON l.l_partkey = p.p_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
INNER JOIN HighSpendingCustomers hsc ON o.o_custkey = hsc.c_custkey
WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY p.p_name, s.s_name
HAVING SUM(l.l_quantity) > 1000
ORDER BY total_quantity DESC, avg_price ASC;