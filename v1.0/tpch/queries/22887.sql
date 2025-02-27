WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS part_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
        AND p.p_retailprice IS NOT NULL
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        CASE 
            WHEN EXISTS (SELECT 1 FROM lineitem l WHERE l.l_partkey = ps.ps_partkey AND l.l_returnflag = 'R') THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    WHERE 
        rs.rn <= 3
)
SELECT 
    fp.p_partkey,
    SUM(sp.ps_availqty) AS total_available,
    AVG(sp.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT sp.ps_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT sp.return_status, ', ') AS return_status_summary
FROM 
    FilteredParts fp
LEFT JOIN 
    SupplierPartInfo sp ON fp.p_partkey = sp.ps_partkey
WHERE 
    fp.part_rank <= 5
GROUP BY 
    fp.p_partkey
HAVING 
    COUNT(sp.ps_suppkey) > 0
ORDER BY 
    total_available DESC NULLS LAST;
