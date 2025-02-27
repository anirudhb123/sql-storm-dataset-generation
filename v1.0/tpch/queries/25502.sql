
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_supply) 
                                                   FROM (SELECT SUM(ps2.ps_supplycost * ps2.ps_availqty) AS total_supply
                                                         FROM supplier s2
                                                         JOIN partsupp ps2 ON s2.s_suppkey = ps2.ps_suppkey
                                                         GROUP BY s2.s_suppkey) AS avg_supply)
),
FinalResults AS (
    SELECT 
        rp.p_name AS part_name,
        rp.p_mfgr AS manufacturer,
        hs.s_name AS supplier_name,
        hs.total_supply_value,
        CONCAT('Region: ', r.r_name, ' | Comments: ', r.r_comment) AS region_info
    FROM 
        RankedParts rp
    JOIN 
        HighValueSuppliers hs ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = hs.s_suppkey LIMIT 1)
    JOIN 
        supplier s ON hs.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    part_name,
    manufacturer,
    supplier_name,
    total_supply_value,
    region_info
FROM 
    FinalResults
WHERE 
    total_supply_value > 10000
ORDER BY 
    total_supply_value DESC, part_name;
