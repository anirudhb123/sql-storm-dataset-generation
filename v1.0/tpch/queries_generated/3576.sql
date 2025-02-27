WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS TotalPartsSupplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM SupplierStats s
    WHERE s.TotalSupplyCost > (
        SELECT AVG(TotalSupplyCost) FROM SupplierStats
    )
),
PremiumCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal >= 1000 THEN 'Premium'
            ELSE 'Regular'
        END AS CustomerCategory
    FROM customer c
)
SELECT 
    pp.p_partkey,
    pp.p_name,
    COALESCE(ss.TotalSupplyCost, 0) AS TotalSupplyCost,
    COALESCE(co.TotalSpent, 0) AS TotalSpent,
    hc.c_name AS HighValueCustomerName,
    ROW_NUMBER() OVER (PARTITION BY pp.p_partkey ORDER BY ss.TotalSupplyCost DESC) AS SupplyRank
FROM part pp
LEFT JOIN SupplierStats ss ON pp.p_partkey = ss.s_suppkey
LEFT JOIN CustomerOrders co ON co.TotalOrders > 5
LEFT JOIN PremiumCustomers pc ON pc.c_custkey = co.c_custkey
LEFT JOIN HighValueSuppliers hs ON hs.s_suppkey = ss.s_suppkey
WHERE pp.p_size > 10 AND pp.p_retailprice IS NOT NULL
ORDER BY TotalSupplyCost DESC, pp.p_partkey;
