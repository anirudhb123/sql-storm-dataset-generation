
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        r.r_name AS region,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.nation,
        s.region,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 3
), 
SupplierProducts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_name LIKE '%widget%'
)
SELECT 
    sp.p_name,
    sp.p_brand,
    sp.p_type,
    COUNT(DISTINCT ts.s_suppkey) AS num_suppliers,
    SUM(ts.s_acctbal) AS total_acct_bal,
    LISTAGG(DISTINCT CONCAT(ts.s_name, ' (', ts.s_address, ')'), '; ') WITHIN GROUP (ORDER BY ts.s_name) AS supplier_details
FROM 
    SupplierProducts sp
JOIN 
    TopSuppliers ts ON sp.ps_suppkey = ts.s_suppkey
GROUP BY 
    sp.p_name, sp.p_brand, sp.p_type
ORDER BY 
    num_suppliers DESC, total_acct_bal DESC;
