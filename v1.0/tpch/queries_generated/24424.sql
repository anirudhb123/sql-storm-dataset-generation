WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IS NOT NULL)
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 'Unknown'
            WHEN p.p_retailprice > 1000 THEN 'Expensive'
            ELSE 'Affordable'
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty 
                     FROM partsupp ps 
                     WHERE ps.ps_supplycost <= 500 AND ps.ps_availqty IS NOT NULL)
),
SupplierPartCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FinalResults AS (
    SELECT 
        fp.p_partkey,
        fp.p_name,
        fp.price_category,
        spc.supplier_count,
        rs.s_name,
        rs.s_acctbal
    FROM 
        FilteredParts fp
    JOIN 
        SupplierPartCount spc ON fp.p_partkey = spc.ps_partkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.rn <= 3 AND rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = fp.p_partkey)
    WHERE 
        fp.price_category = 'Expensive' OR (fp.price_category = 'Unknown' AND spc.supplier_count > 5)
)
SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.price_category,
    COALESCE(fr.s_name, 'No Supplier') AS supplier_name,
    COALESCE(fr.s_acctbal, 0.00) AS supplier_balance,
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    FinalResults fr
LEFT JOIN 
    lineitem l ON l.l_partkey = fr.p_partkey AND l.l_returnflag = 'R'
GROUP BY 
    fr.p_partkey, fr.p_name, fr.price_category, fr.s_name, fr.s_acctbal
HAVING 
    SUM(l.l_extendedprice) > 10000 OR fr.price_category = 'Unknown'
ORDER BY 
    total_revenue DESC, fr.p_partkey
LIMIT 10;
