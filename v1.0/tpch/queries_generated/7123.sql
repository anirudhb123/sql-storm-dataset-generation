WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ps.ps_availqty, 
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS TotalOrders, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 50000
)
SELECT 
    spd.s_name AS SupplierName, 
    spd.p_name AS PartName, 
    spd.p_brand AS Brand, 
    spd.p_retailprice AS RetailPrice, 
    spd.ps_availqty AS AvailableQuantity, 
    hv.TotalSupplyCost AS SupplierTotalSupplyCost, 
    co.c_name AS CustomerName, 
    co.TotalOrders AS CustomerOrderCount, 
    co.TotalSpent AS CustomerTotalSpent
FROM 
    SupplierPartDetails spd
JOIN 
    HighValueSuppliers hv ON spd.s_suppkey = hv.s_suppkey
JOIN 
    CustomerOrders co ON spd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = hv.s_suppkey)
ORDER BY 
    hv.TotalSupplyCost DESC, co.TotalSpent DESC;
