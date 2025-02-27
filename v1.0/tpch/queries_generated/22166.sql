WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_brand = p.p_brand)
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueSuppliers AS (
    SELECT 
        s.n_nationkey, 
        s.total_supply_cost,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.total_supply_cost DESC) AS rn
    FROM 
        SupplierInfo s
    WHERE 
        s.total_supply_cost > 100000
)
SELECT 
    r.r_name, 
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(CASE WHEN p.rn <= 3 THEN p.p_retailprice ELSE 0 END) AS top_part_value,
    AVG(COALESCE(hv.total_supply_cost, 0)) AS avg_high_value_supplier
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedParts p ON p.p_partkey IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps 
                                       JOIN HighValueSuppliers hv ON ps.ps_suppkey = hv.n_nationkey)
LEFT JOIN 
    HighValueSuppliers hv ON n.n_nationkey = hv.n_nationkey
WHERE 
    r.r_name NOT LIKE '%EU%'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > (SELECT COUNT(*) FROM nation) / 2
ORDER BY 
    top_part_value DESC, avg_high_value_supplier;
