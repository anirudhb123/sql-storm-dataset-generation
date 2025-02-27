WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerPreferences AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS average_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
StringManipulation AS (
    SELECT 
        CONCAT(cs.c_name, ' - Preferred Supplier: ', 
               (SELECT s_name FROM RankedSuppliers r WHERE r.rn = 1 AND r.s_suppkey = ps.ps_suppkey LIMIT 1)) AS supplier_info,
        cs.total_orders,
        cs.average_spent
    FROM 
        CustomerPreferences cs
    JOIN 
        partsupp ps ON cs.c_custkey = ps.ps_partkey 
)
SELECT 
    TRIM(REPLACE(supplier_info, ' - Preferred Supplier:', '')) AS refined_supplier_info,
    total_orders,
    ROUND(average_spent, 2) AS avg_spent
FROM 
    StringManipulation
WHERE 
    total_orders > 5
ORDER BY 
    avg_spent DESC;