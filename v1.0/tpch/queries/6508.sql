WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name AS region, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count, 
       SUM(cv.total_spent) AS total_spent_by_customers, 
       SUM(rk.total_cost) AS total_supplier_cost, 
       COUNT(DISTINCT hp.p_partkey) AS high_value_parts_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN RankedSuppliers rk ON s.s_suppkey = rk.s_suppkey
JOIN CustomerOrders cv ON s.s_nationkey = n.n_nationkey
JOIN HighValueParts hp ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = hp.p_partkey)
GROUP BY r.r_name
ORDER BY region;
