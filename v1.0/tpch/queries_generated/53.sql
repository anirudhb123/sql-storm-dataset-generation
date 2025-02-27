WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),

CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),

HighValueSuppliers AS (
    SELECT 
        s.s_name,
        s.total_supply_value,
        cs.c_custkey
    FROM 
        SupplierStats s
    JOIN 
        CustomerStats cs ON s.part_count > 5
    WHERE 
        s.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierStats)
)

SELECT 
    h.s_name,
    h.total_supply_value,
    c.c_name,
    c.total_spent,
    CASE 
        WHEN c.total_spent > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    ROW_NUMBER() OVER(PARTITION BY h.c_custkey ORDER BY h.total_supply_value DESC) AS rn
FROM 
    HighValueSuppliers h
FULL OUTER JOIN 
    CustomerStats c ON h.c_custkey = c.c_custkey
WHERE 
    h.total_supply_value IS NOT NULL OR c.total_spent IS NOT NULL
ORDER BY 
    h.total_supply_value DESC, c.total_spent DESC;
