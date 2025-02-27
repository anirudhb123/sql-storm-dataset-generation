WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
PartsSupplied AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_availqty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
)
SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_spent,
    p.p_name,
    COALESCE(SUM(ps.total_availqty), 0) AS total_available,
    MAX(l.l_shipdate) AS last_ship_date,
    CASE WHEN COUNT(DISTINCT s.s_suppkey) > 0 THEN 'Supplied' ELSE 'Not Supplied' END AS supply_status
FROM customer c
LEFT JOIN CustomerOrders o ON c.c_custkey = o.c_custkey
LEFT JOIN RankedLineItems l ON o.o_orderkey = l.l_orderkey
LEFT JOIN PartsSupplied p ON l.l_partkey = p.p_partkey
LEFT JOIN SupplierHierarchy s ON p.p_partkey = s.s_suppkey
GROUP BY c.c_name, p.p_name
HAVING total_spent > (SELECT AVG(total_spent) FROM (SELECT SUM(o2.o_totalprice) AS total_spent FROM orders o2 GROUP BY o2.o_custkey) AS avg_spent)
ORDER BY total_spent DESC;
