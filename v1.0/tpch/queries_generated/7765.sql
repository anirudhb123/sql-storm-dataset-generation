WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING total_spent > 10000
)
SELECT 
    n.n_name AS nation,
    AVG(rs.total_cost) AS avg_supplier_cost,
    SUM(hc.total_spent) AS total_customer_spending
FROM RankedSuppliers rs
JOIN nation n ON rs.s_nationkey = n.n_nationkey
JOIN HighSpendingCustomers hc ON n.r_regionkey = (
    SELECT r.r_regionkey 
    FROM region r 
    WHERE r.r_name = (
        SELECT r2.r_name 
        FROM region r2 
        JOIN nation n2 ON r2.r_regionkey = n2.n_regionkey 
        WHERE n2.n_nationkey = rs.s_nationkey
    )
)
GROUP BY n.n_name
ORDER BY avg_supplier_cost DESC, total_customer_spending DESC;
