WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 10
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS OrderCount,
        MAX(o.o_totalprice) AS MaxOrderPrice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 0
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS HighTotalPrice
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount < 0.1
    GROUP BY o.o_orderkey, o.o_custkey
),
FinalResults AS (
    SELECT 
        cp.c_custkey,
        cp.OrderCount,
        cp.MaxOrderPrice,
        pp.p_name,
        pp.p_retailprice,
        hs.TotalSupplyCost,
        RANK() OVER (PARTITION BY cp.c_custkey ORDER BY pp.p_retailprice DESC) AS CustProductRank
    FROM CustomerOrders cp
    JOIN RankedParts pp ON cp.MaxOrderPrice > pp.p_retailprice
    LEFT JOIN FilteredSuppliers hs ON pp.p_partkey = hs.s_suppkey
)
SELECT 
    fr.c_custkey,
    fr.OrderCount,
    fr.MaxOrderPrice,
    fr.p_name,
    COALESCE(fr.p_retailprice, 0) AS RetailPrice,
    COALESCE(fr.TotalSupplyCost, 0) AS TotalCost,
    CASE 
        WHEN fr.CustProductRank <= 3 THEN 'Top Product'
        ELSE 'Regular Product'
    END AS ProductCategory
FROM FinalResults fr
WHERE fr.p_retailprice IS NOT NULL
ORDER BY fr.c_custkey, fr.RetailPrice DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
