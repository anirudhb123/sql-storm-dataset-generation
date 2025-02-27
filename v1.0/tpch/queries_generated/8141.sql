WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ss.total_available_qty, 
        ss.total_cost,
        RANK() OVER (ORDER BY ss.total_cost DESC) AS supplier_rank
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        cv.total_spent,
        RANK() OVER (ORDER BY cv.total_spent DESC) AS customer_rank
    FROM CustomerOrders cv
)
SELECT 
    t.s_suppkey, 
    t.s_name, 
    t.s_acctbal, 
    t.total_available_qty, 
    t.total_cost, 
    h.c_custkey, 
    h.c_name, 
    h.total_spent
FROM TopSuppliers t
JOIN HighValueCustomers h ON h.customer_rank <= 10
WHERE t.supplier_rank <= 10
ORDER BY t.total_cost DESC, h.total_spent DESC;
