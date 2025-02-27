
WITH RECURSIVE OrderCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
        AND o.o_orderdate >= DATE '1997-01-01'
), 
PartSupplierCTE AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
), 
NationRegionCTE AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    COALESCE(ps.TotalSupplyCost, 0) AS TotalSupplyCost,
    COUNT(DISTINCT o.o_orderkey) AS OrderCount,
    AVG(l.l_discount) AS AvgDiscount,
    MAX(o.o_totalprice) AS MaxOrderPrice,
    CONCAT(nr.region_name, ' - ', nr.n_name) AS RegionNation,
    STRING_AGG(o.o_comment, '; ') AS OrderComments
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    PartSupplierCTE ps ON ps.ps_partkey = p.p_partkey
JOIN 
    OrderCTE oc ON o.o_orderkey = oc.o_orderkey
JOIN 
    NationRegionCTE nr ON nr.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey LIMIT 1)
WHERE 
    p.p_size > 10
    AND p.p_retailprice < 100.00
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, nr.region_name, nr.n_name, ps.TotalSupplyCost
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    TotalSupplyCost DESC, AvgDiscount ASC;
