WITH SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment,
        p.p_name,
        p.p_retailprice,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS RankSupplier
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
RegionPerformance AS (
    SELECT 
        n.n_name AS nation,
        r.r_name AS region,
        SUM(p.p_retailprice * ps.ps_availqty) AS TotalRetailValue,
        COUNT(DISTINCT s.s_suppkey) AS UniqueSuppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        n.n_name, r.r_name
),
TopSuppliers AS (
    SELECT 
        sd.s_name,
        sd.s_nationkey,
        sd.s_acctbal,
        sd.p_name,
        sd.p_retailprice,
        sd.ps_availqty,
        rp.region,
        rp.nation
    FROM 
        SupplierDetails sd
    JOIN 
        RegionPerformance rp ON sd.s_nationkey = rp.n_nationkey
    WHERE 
        sd.RankSupplier <= 3
)
SELECT 
    ts.s_name AS Supplier_Name,
    rp.region AS Region,
    rp.nation AS Nation,
    SUM(ts.p_retailprice * ts.ps_availqty) AS Total_Value_Managed,
    COUNT(ts.p_name) AS Total_Products_Supplied
FROM 
    TopSuppliers ts
JOIN 
    RegionPerformance rp ON ts.nation = rp.nation
GROUP BY 
    ts.s_name, rp.region, rp.nation
ORDER BY 
    Total_Value_Managed DESC;
