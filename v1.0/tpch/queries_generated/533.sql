WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s_stats.total_supply_cost,
        s_stats.unique_parts_supplied
    FROM 
        SupplierStats s_stats
    WHERE 
        s_stats.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.total_orders,
    o.total_spent,
    COALESCE(hs.unique_parts_supplied, 0) AS unique_parts_from_high_value_suppliers
FROM 
    CustomerOrders o
LEFT JOIN 
    HighValueSuppliers hs ON o.c_custkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            supplier s ON ps.ps_suppkey = s.s_suppkey 
        WHERE 
            ps.ps_partkey IN (
                SELECT p.p_partkey 
                FROM part p 
                WHERE p.p_brand = 'Brand#42'
            ) 
        LIMIT 1
    )
WHERE 
    o.total_spent IS NOT NULL
ORDER BY 
    o.total_spent DESC
LIMIT 100;
