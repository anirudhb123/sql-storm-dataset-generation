WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.total_value
    FROM 
        RankedSuppliers r
    JOIN 
        supplier s ON r.s_suppkey = s.s_suppkey
    WHERE 
        r.supplier_rank <= 5
)
SELECT 
    n.n_name AS nation_name,
    SUM(ts.total_value) AS total_supply_value,
    COUNT(DISTINCT ts.s_suppkey) AS supplier_count
FROM 
    TopSuppliers ts
JOIN 
    supplier s ON ts.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_supply_value DESC;
