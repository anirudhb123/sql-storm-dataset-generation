WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2023-01-01'
), 
SupplierTotalCost AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    COALESCE(STC.TotalSupplyCost, 0) AS SupplyCost,
    COUNT(DISTINCT LO.l_orderkey) AS OrderCount,
    AVG(LO.l_discount) AS AverageDiscount,
    SUM(LO.l_quantity * (1 - LO.l_discount)) AS TotalRevenue,
    CASE 
        WHEN p.p_retailprice IS NULL THEN 'Price Unknown'
        WHEN p.p_retailprice <= 100 THEN 'Affordable'
        WHEN p.p_retailprice > 100 AND p.p_retailprice <= 500 THEN 'Moderate'
        ELSE 'Expensive' 
    END AS PriceCategory
FROM 
    part p
LEFT JOIN 
    lineitem LO ON p.p_partkey = LO.l_partkey
LEFT JOIN 
    SupplierTotalCost STC ON p.p_partkey = STC.ps_partkey
LEFT JOIN 
    RankedOrders R ON R.o_orderkey = LO.l_orderkey AND R.OrderRank <= 10
WHERE 
    (LO.l_returnflag = 'N' OR LO.l_returnflag IS NULL)
    AND (p.p_mfgr LIKE '%ACME%' OR p.p_comment ILIKE '%special%')
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, SupplyCost
HAVING 
    COUNT(DISTINCT LO.l_orderkey) > 5 
    OR SUM(LO.l_extendedprice * (1 - LO.l_discount)) > 1000
ORDER BY 
    TotalRevenue DESC, SupplyCost ASC;
