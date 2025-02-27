WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_container,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_container ORDER BY ps.ps_supplycost DESC) AS Rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_name LIKE '%Steel%'
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name,
        r.r_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
)
SELECT 
    rp.p_name, 
    rp.p_container, 
    rp.ps_supplycost, 
    fs.s_name, 
    fs.n_name, 
    fs.r_name 
FROM 
    RankedParts rp
JOIN 
    FilteredSuppliers fs ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < rp.ps_supplycost)
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.ps_supplycost DESC, fs.s_name;
