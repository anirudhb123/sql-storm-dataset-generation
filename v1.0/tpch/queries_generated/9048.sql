WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING AVG(ps.ps_supplycost) > 500
),
CustomerOrderStats AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING total_spent > 10000
)
SELECT 
    rs.nation_name, 
    hp.p_name, 
    c.total_spent, 
    c.order_count
FROM RankedSuppliers rs
JOIN HighValueParts hp ON hp.avg_supplycost > 600
JOIN CustomerOrderStats c ON c.total_spent > 15000
WHERE rs.rank <= 3
ORDER BY rs.nation_name, c.total_spent DESC;
