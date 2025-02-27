
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(*) AS supplier_count,
        SUM(rs.total_cost) AS total_spent
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
    WHERE rs.rank <= 5
    GROUP BY r.r_regionkey, r.r_name
)
SELECT 
    r.r_name AS region_name,
    ts.supplier_count,
    ts.total_spent,
    AVG(o.o_totalprice) AS average_order_value
FROM TopSuppliers ts
JOIN region r ON ts.r_regionkey = r.r_regionkey
LEFT JOIN orders o ON o.o_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey IN (
        SELECT n.n_nationkey
        FROM nation n
        WHERE n.n_regionkey = r.r_regionkey
    )
)
GROUP BY r.r_name, ts.supplier_count, ts.total_spent
ORDER BY ts.total_spent DESC, r.r_name;
