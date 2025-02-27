WITH PartSupplierInfo AS (
    SELECT 
        p.p_name AS Part_Name,
        s.s_name AS Supplier_Name,
        s.s_acctbal AS Supplier_Account_Balance,
        p.p_retailprice AS Retail_Price,
        ps.ps_availqty AS Available_Quantity,
        ps.ps_supplycost AS Supply_Cost,
        CONCAT(s.s_name, ' (', p.p_name, ') - Price: $', FORMAT(p.p_retailprice, 2)) AS PartSupplier_Description
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
FinalBenchmark AS (
    SELECT 
        Part_Name,
        Supplier_Name,
        Retail_Price,
        Available_Quantity,
        Supplier_Account_Balance,
        Supply_Cost,
        PartSupplier_Description,
        LENGTH(PartSupplier_Description) AS Description_Length,
        UPPER(Part_Name) AS Uppercase_Part_Name,
        LOWER(Supplier_Name) AS Lowercase_Supplier_Name
    FROM 
        PartSupplierInfo
)
SELECT 
    Part_Name,
    Supplier_Name,
    Retail_Price,
    Available_Quantity,
    Supplier_Account_Balance,
    Supply_Cost,
    PartSupplier_Description,
    Description_Length,
    Uppercase_Part_Name,
    Lowercase_Supplier_Name
FROM 
    FinalBenchmark
WHERE 
    Description_Length > 50
ORDER BY 
    Retail_Price DESC, 
    Supplier_Account_Balance ASC;
