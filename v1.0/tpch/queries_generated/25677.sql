WITH StringAggregates AS (
    SELECT 
        n.n_name AS Nation,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
        STRING_AGG(DISTINCT p.p_name, ', ') AS PartNames,
        STRING_AGG(DISTINCT c.c_name, ', ') AS CustomerNames
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    GROUP BY 
        n.n_name
)
SELECT 
    Nation,
    SupplierCount,
    LENGTH(PartNames) AS TotalPartNameLength,
    LENGTH(CustomerNames) AS TotalCustomerNameLength,
    SUBSTRING(PartNames, 1, 100) AS SampleParts,
    SUBSTRING(CustomerNames, 1, 100) AS SampleCustomers
FROM 
    StringAggregates
WHERE 
    LENGTH(PartNames) > 0 OR LENGTH(CustomerNames) > 0
ORDER BY 
    SupplierCount DESC;
