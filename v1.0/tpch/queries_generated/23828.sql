WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(psi.total_supply_cost, 0) AS total_supply_cost,
        psi.supplier_count
    FROM 
        part p
    LEFT JOIN 
        PartSupplierInfo psi ON p.p_partkey = psi.ps_partkey
    WHERE 
        (p.p_size BETWEEN 1 AND 5 OR p.p_size IS NULL)
        AND (p.p_retailprice > 0 OR p.p_retailprice IS NULL)
),
RegionSupplier AS (
    SELECT 
        r.r_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        r.r_name IS NOT NULL
),
FinalResult AS (
    SELECT 
        fp.p_partkey,
        fp.p_name,
        fp.p_retailprice,
        fp.total_supply_cost,
        fp.supplier_count,
        rs.s_name AS top_supplier
    FROM 
        FilteredParts fp
    LEFT JOIN 
        RankedSuppliers rs ON fp.total_supply_cost = (SELECT MAX(total_supply_cost) 
                                                       FROM FilteredParts 
                                                       WHERE fp.p_partkey = p_partkey)
    WHERE 
        fp.supplier_count > 0
)

SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.p_retailprice,
    fr.total_supply_cost,
    fr.supplier_count,
    COALESCE(fr.top_supplier, 'No Supplier') AS headline_supplier
FROM 
    FinalResult fr
WHERE 
    fr.total_supply_cost > (SELECT AVG(total_supply_cost) FROM PartSupplierInfo)
ORDER BY 
    CASE 
        WHEN fr.supplier_count = 0 THEN 1
        ELSE 0
    END,
    fr.p_retailprice DESC;
