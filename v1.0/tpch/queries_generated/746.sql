WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ROUND(SUM(ps.ps_supplycost * ps.ps_availqty), 2) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        ns.n_name AS nation_name, 
        rs.s_name AS supplier_name, 
        rs.total_supply_value
    FROM RankedSuppliers rs
    JOIN nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    WHERE rs.rn <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 50000
)
SELECT 
    TO_CHAR(co.total_spent, '999,999,999,999.99') AS customer_total_spent,
    ts.nation_name,
    ts.supplier_name,
    ts.total_supply_value
FROM TopSuppliers ts
FULL OUTER JOIN CustomerOrders co ON ts.nation_name IS NOT NULL AND co.c_custkey IS NOT NULL
WHERE ts.total_supply_value IS NOT NULL 
ORDER BY co.total_spent DESC NULLS LAST, ts.total_supply_value DESC;
