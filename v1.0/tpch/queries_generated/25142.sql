WITH SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' at a cost of $', FORMAT(ps.ps_supplycost, 2)) AS SupplyDetails
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSpent,
        COUNT(o.o_orderkey) AS TotalOrders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey
),
CombinedInfo AS (
    SELECT 
        spi.s_suppkey,
        spi.s_name,
        spi.p_partkey,
        spi.p_name,
        co.c_custkey,
        co.c_name,
        co.TotalSpent,
        co.TotalOrders,
        spi.SupplyDetails
    FROM 
        SupplierPartInfo spi
    JOIN 
        CustomerOrderInfo co ON spi.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = spi.s_suppkey)
)
SELECT 
    s.s_name AS SupplierName,
    p.p_name AS PartName,
    c.c_name AS CustomerName,
    SUM(co.TotalSpent) AS TotalSpentByCustomer,
    COUNT(co.TotalOrders) AS TotalOrdersByCustomer,
    GROUP_CONCAT(DISTINCT spi.SupplyDetails SEPARATOR '; ') AS CombinedSupplyDetails
FROM 
    CombinedInfo co
JOIN 
    supplier s ON co.s_suppkey = s.s_suppkey
JOIN 
    part p ON co.p_partkey = p.p_partkey
JOIN 
    customer c ON co.c_custkey = c.c_custkey
GROUP BY 
    s.s_name, p.p_name, c.c_name
HAVING 
    TotalSpentByCustomer > 1000
ORDER BY 
    TotalSpentByCustomer DESC;
