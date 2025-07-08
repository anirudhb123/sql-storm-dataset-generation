
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank,
        p.p_name,
        p.p_type
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        r.s_suppkey, 
        r.s_name, 
        r.p_name, 
        r.p_type, 
        r.s_acctbal
    FROM 
        RankedSuppliers r
    WHERE 
        r.rank <= 3
)
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT fs.s_suppkey) AS number_of_suppliers,
    SUM(fs.s_acctbal) AS total_account_balance,
    LISTAGG(DISTINCT fs.p_name, ', ') WITHIN GROUP (ORDER BY fs.p_name) AS product_names
FROM 
    FilteredSuppliers fs
JOIN 
    supplier sup ON fs.s_suppkey = sup.s_suppkey
JOIN 
    nation ns ON sup.s_nationkey = ns.n_nationkey
GROUP BY 
    ns.n_name
ORDER BY 
    total_account_balance DESC;
