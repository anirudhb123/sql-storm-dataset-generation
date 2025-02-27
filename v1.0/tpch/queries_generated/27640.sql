WITH SupplierDetails AS (
    SELECT 
        s.s_name AS SupplierName,
        s.s_address AS SupplierAddress,
        s.s_phone AS SupplierPhone,
        n.n_name AS NationName,
        r.r_name AS RegionName,
        CONCAT(s.s_name, ' from ', n.n_name, ', ', r.r_name) AS FullSupplierDescription
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_name AS PartName,
        p.p_mfgr AS Manufacturer,
        p.p_retailprice AS RetailPrice,
        REPLACE(p.p_comment, sprintf('part', 'PART'), 'PARTICULAR') AS ProcessedComment,
        LENGTH(p.p_comment) AS CommentLength
    FROM 
        part p
),
OrderSummary AS (
    SELECT 
        o.o_orderkey AS OrderKey,
        o.o_orderdate AS OrderDate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(*) AS TotalLineItems
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
FinalBenchmark AS (
    SELECT 
        sd.FullSupplierDescription,
        pd.PartName,
        pd.Manufacturer,
        pd.RetailPrice,
        pd.ProcessedComment,
        os.TotalRevenue,
        os.TotalLineItems
    FROM 
        SupplierDetails sd
    CROSS JOIN 
        PartDetails pd
    JOIN 
        OrderSummary os ON os.TotalLineItems > 0
    WHERE 
        pd.CommentLength > 10
)
SELECT 
    *
FROM 
    FinalBenchmark
ORDER BY 
    sd.FullSupplierDescription, pd.RetailPrice DESC;
