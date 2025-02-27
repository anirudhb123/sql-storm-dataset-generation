WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
    HAVING AVG(ps.ps_supplycost) > 100.00
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
)
SELECT rs.nation, p.p_name, p.avg_supplycost, co.total_amount
FROM RankedSuppliers rs
JOIN HighValueParts p ON rs.rank = 1
JOIN CustomerOrders co ON co.total_amount > (SELECT AVG(global.total_amount) 
                                              FROM CustomerOrders global)
WHERE rs.s_acctbal > 5000
ORDER BY rs.nation, p.avg_supplycost DESC;
