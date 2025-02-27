WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PopularParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS total_sold
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '2023-01-01' 
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_quantity) > 100
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
)
SELECT rs.s_name, pp.p_name, co.order_count
FROM RankedSuppliers rs
JOIN PopularParts pp ON pp.total_sold > 200
JOIN CustomerOrders co ON co.order_count > 5
WHERE rs.rn = 1
ORDER BY rs.s_acctbal DESC, co.order_count DESC;
