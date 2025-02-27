WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, o.o_orderkey, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT r.r_name, rs.s_name AS supplier_name, h.c_name AS customer_name, 
       h.o_totalprice, rs.total_cost
FROM RankedSuppliers rs
JOIN nation r ON rs.s_nationkey = r.n_nationkey
JOIN HighValueCustomers h ON h.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey IN (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_retailprice > 1000
    )
)
WHERE rs.rank <= 5
ORDER BY r.r_name, rs.total_cost DESC, h.o_totalprice DESC;
