WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey, 
    cs.c_name, 
    rs.s_name AS top_supplier, 
    cs.total_spent,
    p.p_type AS product_type,
    LENGTH(cs.c_name) AS name_length,
    CONCAT(cs.c_name, ' - ', rs.top_supplier) AS cust_supplier_link
FROM 
    CustomerOrders cs
JOIN 
    RankedSuppliers rs ON rs.rnk = 1
JOIN 
    partsupp ps ON rs.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_size BETWEEN 10 AND 30
ORDER BY 
    cs.total_spent DESC;
