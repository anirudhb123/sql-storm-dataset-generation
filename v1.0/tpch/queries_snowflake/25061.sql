
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk,
        p.p_type
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 50000
),
TopSuppliers AS (
    SELECT 
        p_type,
        LISTAGG(s_name, ', ') WITHIN GROUP (ORDER BY s_name) AS supplier_names 
    FROM 
        RankedSuppliers 
    WHERE 
        rnk <= 3
    GROUP BY 
        p_type
)
SELECT 
    p.p_name,
    p.p_type,
    ts.supplier_names,
    p.p_retailprice
FROM 
    part p
JOIN 
    TopSuppliers ts ON p.p_type = ts.p_type
WHERE 
    p.p_retailprice BETWEEN 100.00 AND 500.00
ORDER BY 
    p.p_type, p.p_retailprice DESC;
