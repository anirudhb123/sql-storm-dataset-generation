WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 1000
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    r1.s_name AS supplier_name,
    r1.p_name AS part_name,
    r2.c_name AS customer_name,
    r2.total_spent AS customer_total_spent
FROM 
    RankedSuppliers r1
JOIN 
    HighValueCustomers r2 ON r1.rn = 1
WHERE 
    r1.s_acctbal > 2000
ORDER BY 
    r1.s_acctbal DESC, r2.total_spent DESC;
