WITH StringBenchmark AS (
    SELECT 
        p.p_name AS PartName,
        s.s_name AS SupplierName,
        c.c_name AS CustomerName,
        n.n_name AS NationName,
        o.o_orderkey AS OrderKey,
        o.o_orderdate AS OrderDate,
        COUNT(l.l_orderkey) AS LineItemCount,
        SUM(l.l_extendedprice) AS TotalExtendedPrice,
        CONCAT(p.p_name, ' - ', s.s_name, ' ', c.c_name) AS FullDescription,
        LENGTH(CONCAT(p.p_name, ' - ', s.s_name, ' ', c.c_name)) AS DescriptionLength,
        UPPER(REPLACE(CONCAT(n.n_name, ' ', c.c_name), ' ', '_')) AS UpperNationCustomer
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        p.p_name, s.s_name, c.c_name, n.n_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    PartName,
    SupplierName,
    CustomerName,
    NationName,
    OrderKey,
    OrderDate,
    LineItemCount,
    TotalExtendedPrice,
    FullDescription,
    DescriptionLength,
    UpperNationCustomer
FROM 
    StringBenchmark
ORDER BY 
    DescriptionLength DESC, TotalExtendedPrice ASC;
