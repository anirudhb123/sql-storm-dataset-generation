WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
), TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        p.p_partkey,
        p.p_name
    FROM RankedSuppliers rs
    JOIN part p ON rs.p_partkey = p.p_partkey
    WHERE rs.rank <= 3
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT 
    co.c_name AS customer_name,
    ts.s_name AS supplier_name,
    ts.p_name AS part_name,
    ts.total_supply_cost
FROM TopSuppliers ts
JOIN CustomerOrders co ON co.c_custkey = (
    SELECT o.o_custkey 
    FROM orders o 
    WHERE o.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = ts.p_partkey 
        GROUP BY l.l_orderkey 
        HAVING SUM(l.l_quantity) > 10
    ) 
    LIMIT 1
)
ORDER BY co.customer_name, ts.s_name;
