WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON rs.nation_name = (
            SELECT n.n_name 
            FROM nation n 
            WHERE n.n_nationkey = (
                SELECT s.s_nationkey 
                FROM supplier s 
                WHERE s.s_suppkey = rs.s_suppkey
            )
        )
    WHERE 
        rs.rn = 1
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        ps.ps_supplycost,
        ps.ps_availqty,
        ps.ps_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 100 
)
SELECT 
    hs.r_name,
    hs.s_name,
    hs.s_acctbal,
    pd.p_name,
    pd.p_size,
    pd.ps_supplycost,
    pd.ps_availqty
FROM 
    HighValueSuppliers hs
JOIN 
    ProductDetails pd ON hs.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_quantity > 20
        )
    )
ORDER BY 
    hs.r_name, 
    hs.s_acctbal DESC, 
    pd.ps_supplycost;
