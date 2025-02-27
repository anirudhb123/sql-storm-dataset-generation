WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS RankWithinNation
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_mfgr,
        COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20) 
        OR p.p_mfgr LIKE '%Inc%' 
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_mfgr
    HAVING 
        COUNT(ps.ps_suppkey) > 1
),
DetailsOrder AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        AVG(l.l_tax) AS AverageTax
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2021-01-01' AND '2021-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
AggregatedData AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        d.TotalRevenue,
        d.AverageTax,
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY d.TotalRevenue DESC) AS RevenueRank
    FROM 
        DetailsOrder d
    JOIN 
        lineitem l ON d.o_orderkey = l.l_orderkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
)
SELECT 
    r.n_nationkey,
    r.r_name,
    COALESCE(SUM(a.TotalRevenue), 0) AS TotalRevenuePerNation,
    COALESCE(SUM(a.AverageTax), 0) AS TotalTaxPerNation
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    AggregatedData a ON s.s_suppkey = a.p_partkey
WHERE 
    s.s_acctbal IS NOT NULL
    AND EXISTS (
        SELECT 1 
        FROM RankedSuppliers 
        WHERE RankWithinNation = 1 AND s.s_suppkey = s.s_suppkey
    )
GROUP BY 
    r.n_nationkey, r.r_name
ORDER BY 
    TotalRevenuePerNation DESC, TotalTaxPerNation ASC
LIMIT 10;
