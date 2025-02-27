WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, rs.total_cost
    FROM RankedSuppliers rs
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    WHERE rs.supplier_rank <= 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT c.c_name AS CustomerName, c.total_spent AS TotalSpent, s.s_name AS SupplierName, 
       s.total_cost AS SupplierTotalCost
FROM CustomerOrders c
JOIN TopSuppliers s ON c.total_spent > s.total_cost
WHERE c.total_spent > 10000
ORDER BY c.total_spent DESC, s.total_cost ASC;
