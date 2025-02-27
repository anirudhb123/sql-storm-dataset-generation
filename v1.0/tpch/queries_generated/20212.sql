WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
SupplierSummary AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT p.p_partkey) AS TotalPartsSupplied,
        AVG(p.p_retailprice) AS AvgRetailPrice
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_suppkey
),
NationWithComments AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(n.n_comment, 'No Comment Available') AS Comment
    FROM 
        nation n
    WHERE 
        n.n_name NOT LIKE 'A%'
)
SELECT 
    RANK() OVER (ORDER BY OSS.SupplierTotal DESC) AS Rank,
    OSS.NationKey,
    OSS.SupplierName,
    OSS.SupplierTotal,
    OSS.Comment
FROM (
    SELECT 
        s.s_nationkey AS NationKey,
        s.s_name AS SupplierName,
        SUM(ss.TotalSupplyCost) AS SupplierTotal,
        nwc.Comment
    FROM 
        supplier s
    JOIN 
        SupplierSummary ss ON s.s_suppkey = ss.ps_suppkey
    LEFT JOIN 
        NationWithComments nwc ON s.s_nationkey = nwc.n_nationkey
    GROUP BY 
        s.s_nationkey, s.s_name, nwc.Comment
) OSS
WHERE 
    OSS.SupplierTotal > (
        SELECT 
            AVG(O.o_totalprice)
        FROM 
            RankedOrders O
    )
UNION ALL
SELECT 
    NULL AS Rank,
    n.n_nationkey AS NationKey,
    'Unknown' AS SupplierName,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS SupplierTotal,
    'Aggregated from Lineitem' AS Comment
FROM 
    lineitem l
WHERE 
    l.l_shipdate < '2023-06-01'
GROUP BY 
    n.n_nationkey
ORDER BY 
    Rank, SupplierTotal DESC;
