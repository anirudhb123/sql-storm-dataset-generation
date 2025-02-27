WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal > 1000 THEN 'High'
            WHEN s.s_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS BalCategory
    FROM 
        supplier s
    WHERE 
        s.s_comment IS NOT NULL
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost) AS TotalSupplyCost,
        COUNT(ps.ps_suppkey) AS SupplierCount
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice IS NOT NULL
    GROUP BY 
        p.p_partkey, p.p_name
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
        o.o_orderdate BETWEEN '2022-01-01' AND CURRENT_DATE
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    RANK() OVER (ORDER BY cd.TotalSpent DESC) AS CustomerRank,
    cd.c_name,
    cd.OrderCount,
    cd.TotalSpent,
    sp.s_name AS SupplierName,
    pd.p_name AS ProductName,
    pd.TotalSupplyCost,
    COALESCE(sp.BalCategory, 'Unknown') AS SupplierBalanceCategory,
    o.o_orderdate
FROM 
    CustomerOrders cd
JOIN 
    RankedOrders o ON cd.OrderCount > 2
LEFT JOIN 
    SupplierDetails sp ON sp.s_acctbal < cd.TotalSpent
CROSS JOIN 
    ProductDetails pd
WHERE 
    pd.SupplierCount > 0 AND 
    (cd.TotalSpent BETWEEN 1000 AND 10000 OR cd.OrderCount > 5)
ORDER BY 
    CustomerRank, TotalSpent DESC;
