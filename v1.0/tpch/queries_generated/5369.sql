WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, AVG(l.l_extendedprice) AS avg_price
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate > '2023-01-01'
    GROUP BY p.p_partkey, p.p_name
    HAVING AVG(l.l_extendedprice) > 1000
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name,
       SUM(HighValueParts.avg_price) AS total_avg_price_parts,
       COUNT(DISTINCT CustomerOrders.c_custkey) AS unique_customers,
       SUM(RankedSuppliers.total_supply_cost) AS total_supply_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN RankedSuppliers ON s.s_suppkey = RankedSuppliers.s_suppkey
JOIN HighValueParts ON HighValueParts.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN CustomerOrders ON CustomerOrders.c_custkey IN (SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_shipdate > '2023-01-01')
GROUP BY r.r_name
ORDER BY total_supply_cost DESC, total_avg_price_parts DESC;
