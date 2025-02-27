WITH CustomerPartDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        p.p_name,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        CONCAT(c.c_name, ' ordered ', l.l_quantity, ' of ', p.p_name, 
               ' on ', o.o_orderdate, 
               ' with a total extended price of ', ROUND(l.l_extendedprice * (1 - l.l_discount) + l.l_tax, 2)) AS Summary
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        l.l_returnflag = 'N' 
        AND l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    COUNT(DISTINCT p.p_partkey) AS UniquePartsCount, 
    SUM(l.l_extendedprice * (1 - l.l_discount) + l.l_tax) AS TotalSpent, 
    STRING_AGG(Summary, '; ') AS OrderSummaries
FROM 
    CustomerPartDetails
GROUP BY 
    c.c_custkey, c.c_name
ORDER BY 
    TotalSpent DESC
LIMIT 10;
