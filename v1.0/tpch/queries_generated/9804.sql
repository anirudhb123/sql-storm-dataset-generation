WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 3
), 
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING total_cost > 50000
), 
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
SupplierPerformance AS (
    SELECT sh.s_suppkey, sh.s_name, p.p_name, COUNT(l.l_orderkey) AS order_count
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY sh.s_suppkey, sh.s_name, p.p_name
)
SELECT cs.c_custkey, cs.c_name, coalesce(sp.order_count, 0) AS supplier_order_count, 
       coalesce(hv.total_cost, 0) AS high_value_part_cost, 
       cs.order_count AS customer_order_count, cs.total_spent
FROM CustomerOrderStats cs
LEFT JOIN SupplierPerformance sp ON cs.c_custkey = sp.s_suppkey
LEFT JOIN HighValueParts hv ON sp.p_name = hv.p_name
WHERE cs.total_spent > 1000 AND cs.order_count > 5
ORDER BY cs.total_spent DESC, cs.order_count DESC;
