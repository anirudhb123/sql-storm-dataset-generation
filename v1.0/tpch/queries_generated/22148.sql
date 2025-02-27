WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as SupplierRank
    FROM 
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS OrderTotal
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipdate IS NOT NULL AND 
        YEAR(o.o_orderdate) = 2023
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS TotalQuantity,
        AVG(l.l_extendedprice) AS AveragePrice
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(l.l_quantity) > 100
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    COALESCE(tp.TotalQuantity, 0) AS PartTotalQuantity,
    COALESCE(tp.AveragePrice, 0) AS PartAveragePrice,
    s.s_name AS SupplierName,
    s.s_acctbal AS SupplierBalance,
    CASE 
        WHEN s.SupplierRank IS NOT NULL AND s.SupplierRank <= 5 THEN 'Top Supplier'
        ELSE 'Other Supplier'
    END AS SupplierStatus
FROM 
    CustomerOrders o 
JOIN 
    TopParts tp ON o.o_orderkey = tp.p_partkey
LEFT JOIN 
    RankedSuppliers s ON tp.p_partkey = s.ps_partkey
WHERE 
    (o.OrderTotal > 500 OR o.c_custkey IN (SELECT c_custkey FROM customer WHERE c_mktsegment = 'BUILDING'))
    AND s.s_name IS NOT NULL
ORDER BY 
    o.o_orderdate DESC, o.OrderTotal DESC, PartTotalQuantity ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
