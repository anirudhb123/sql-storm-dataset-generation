WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_name IN ('FRANCE', 'GERMANY', 'USA')
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    JOIN RankedSuppliers s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING s.rank <= 3
),
FrequentCustomers AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT r.r_name, t.s_name, f.c_name, t.total_supply_value, f.order_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN TopSuppliers t ON n.n_nationkey IN (SELECT s_nationkey FROM supplier WHERE s_suppkey = t.s_suppkey)
JOIN FrequentCustomers f ON f.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN 
    (SELECT DISTINCT l.l_orderkey 
     FROM lineitem l 
     JOIN partsupp ps ON l.l_partkey = ps.ps_partkey 
     WHERE ps.ps_supplycost < 50.00))
ORDER BY r.r_name, t.total_supply_value DESC, f.order_count DESC;
