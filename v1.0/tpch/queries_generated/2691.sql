WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank = 1
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(ts.s_name, 'No Supplier') AS top_supplier,
    CASE 
        WHEN ps.ps_availqty IS NULL THEN 0
        ELSE ps.ps_availqty
    END AS available_quantity,
    (p.p_retailprice * COALESCE(ts.s_acctbal, 1)) AS price_supplier_balance_ratio,
    r.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    TopSuppliers ts ON ts.s_suppkey = ps.ps_suppkey
INNER JOIN 
    nation n ON n.n_nationkey = (
        SELECT 
            c.c_nationkey 
        FROM 
            customer c 
        JOIN 
            orders o ON c.c_custkey = o.o_custkey 
        WHERE 
            o.o_totalprice > 1000 
        LIMIT 1
    )
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 1 AND 50
ORDER BY 
    p.p_partkey;
