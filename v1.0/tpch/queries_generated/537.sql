WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, ps.ps_partkey
),

CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

TopSuppliers AS (
    SELECT 
        r.n_name AS nation_name, 
        rs.s_name, 
        rs.total_supply_cost
    FROM RankedSuppliers rs
    JOIN partsupp ps ON rs.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN nation r ON s.s_nationkey = r.n_nationkey
    WHERE rs.rn = 1
)

SELECT 
    co.c_custkey, 
    co.c_name,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    COALESCE(co.total_orders, 0) AS total_orders,
    COALESCE(co.total_spent, 0.00) AS total_spent,
    COUNT(DISTINCT l.l_orderkey) AS distinct_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_order_value
FROM CustomerOrders co
LEFT JOIN lineitem l ON co.c_custkey = l.l_orderkey
LEFT JOIN TopSuppliers ts ON ts.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey))
GROUP BY co.c_custkey, co.c_name, ts.s_name
ORDER BY total_spent DESC, total_orders DESC;
