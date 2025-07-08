
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn,
        s.s_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name
    FROM 
        CustomerOrders c
    WHERE 
        c.total_spent > (
            SELECT AVG(total_spent) FROM CustomerOrders
        )
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 3 AND rs.total_supply_value > 10000
)

SELECT 
    hvc.c_custkey,
    hvc.c_name,
    fs.s_suppkey,
    fs.s_name,
    COALESCE(SUM(l.l_discount), 0) AS total_discounted_value,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    orders o ON hvc.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    FilteredSuppliers fs ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE 
            ps.ps_suppkey = fs.s_suppkey 
            AND ps.ps_partkey IN (
                SELECT p.p_partkey 
                FROM part p 
                WHERE p.p_retailprice < 100.00
            )
    )
GROUP BY 
    hvc.c_custkey, hvc.c_name, fs.s_suppkey, fs.s_name
HAVING 
    COALESCE(SUM(l.l_discount), 0) > 5000
ORDER BY 
    hvc.c_name, total_discounted_value DESC;
