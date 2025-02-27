WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 10 AND SUM(o.o_totalprice) > 100000
),
FinalReport AS (
    SELECT r.r_name AS region, 
           n.n_name AS nation,
           c.c_custkey AS customer_id, 
           c.order_count, 
           c.total_spent,
           p.p_partkey AS part_id, 
           SUM(l.l_quantity) AS total_quantity
    FROM CustomerOrders c
    JOIN nation n ON c.c_custkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    JOIN HighValueParts p ON l.l_partkey = p.ps_partkey
    GROUP BY r.r_name, n.n_name, c.c_custkey, c.order_count, c.total_spent, p.p_partkey
)
SELECT region, nation, customer_id, order_count, total_spent, part_id, total_quantity
FROM FinalReport
ORDER BY region, nation, customer_id, order_count DESC;
