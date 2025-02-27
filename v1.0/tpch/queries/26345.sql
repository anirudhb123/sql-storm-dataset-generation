WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' at a price of ', CAST(ps.ps_supplycost AS CHAR), ' each') AS supply_details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 100
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        CONCAT(n.n_name, ' is located in ', r.r_name) AS nation_region
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sp.s_name AS Supplier_Name,
    sp.p_name AS Part_Name,
    sp.p_retailprice AS Retail_Price,
    nr.region_name AS Region_Name,
    sp.supply_details,
    nr.nation_region
FROM 
    SupplierParts sp
JOIN 
    NationRegion nr ON sp.s_nationkey = nr.n_nationkey
ORDER BY 
    sp.p_retailprice DESC, sp.s_name;
