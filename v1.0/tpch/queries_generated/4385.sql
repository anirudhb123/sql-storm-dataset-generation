WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        p.p_brand,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        c.c_mktsegment = 'BUILDING'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_name,
    co.OrderCount,
    co.TotalSpent,
    sp.p_name,
    sp.ps_availqty,
    CASE 
        WHEN ro.OrderRank = 1 THEN 'Top Order'
        ELSE 'Regular Order'
    END AS OrderStatus,
    CONCAT('Supplier: ', sp.s_name, ' | Cost: $', ROUND(sp.ps_supplycost, 2)) AS SupplierInfo
FROM 
    CustomerOrders co
LEFT JOIN 
    RankedOrders ro ON co.OrderCount > 0
LEFT JOIN 
    SupplierPartDetails sp ON co.OrderCount > 5 AND sp.SupplierRank <= 3
WHERE 
    (co.TotalSpent IS NOT NULL OR co.TotalSpent <> 0)
ORDER BY 
    co.TotalSpent DESC, 
    co.c_name;
