WITH CombinedInfo AS (
    SELECT 
        p.p_name, 
        s.s_name,
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        l.l_quantity, 
        l.l_extendedprice,
        CONCAT(s.s_name, ': ', p.p_name) AS SupplierPart, 
        CONCAT(c.c_name, ' - Order: ', o.o_orderkey) AS CustomerOrder,
        DATE_PART('year', o.o_orderdate) AS OrderYear,
        COUNT(DISTINCT l.l_orderkey) OVER(PARTITION BY p.p_partkey) AS TotalOrdersForPart
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        TRIM(p.p_comment) LIKE '%special%'
        AND o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
)
SELECT 
    OrderYear, 
    SupplierPart, 
    CustomerOrder, 
    SUM(l_quantity) AS TotalQuantity, 
    SUM(l_extendedprice) AS TotalRevenue, 
    AVG(o_totalprice) AS AverageOrderValue
FROM 
    CombinedInfo
GROUP BY 
    OrderYear, SupplierPart, CustomerOrder
ORDER BY 
    TotalRevenue DESC, TotalQuantity DESC
LIMIT 100;
