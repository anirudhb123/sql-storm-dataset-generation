WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM 
        part p
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_address, ''), 'Unknown Address') AS s_address,
        SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 0
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(DISTINCT l.l_orderkey) AS LineItemCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalLineItemRevenue
    FROM 
        orders o 
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice BETWEEN 100 AND 5000
    GROUP BY 
        o.o_orderkey, o.o_totalprice
), NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS r_name,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    pi.p_partkey,
    pi.p_name,
    pi.p_retailprice,
    si.TotalSupplyCost,
    os.LineItemCount,
    os.TotalLineItemRevenue,
    nd.SupplierCount,
    CASE 
        WHEN pi.PriceRank = 1 THEN 'Most Expensive'
        WHEN pi.PriceRank >= 2 AND pi.PriceRank <= 3 THEN 'Expensive'
        ELSE 'Affordable'
    END AS PriceCategory
FROM 
    RankedParts pi
LEFT JOIN 
    SupplierInfo si ON pi.p_partkey = (SELECT ps.ps_partkey 
                                         FROM partsupp ps 
                                         WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_acctbal > 0)
                                         ORDER BY ps.ps_supplycost LIMIT 1)
LEFT JOIN 
    OrderSummary os ON os.o_totalprice = (SELECT MIN(o.o_totalprice) 
                                           FROM orders o 
                                           WHERE o.o_orderstatus = 'O')
LEFT JOIN 
    NationDetails nd ON nd.n_nationkey = (SELECT s.s_nationkey 
                                           FROM supplier s 
                                           WHERE s.s_suppkey = (SELECT ps.ps_supplycost 
                                                                FROM partsupp ps 
                                                                WHERE ps.ps_partkey = pi.p_partkey 
                                                                ORDER BY ps.ps_supplycost DESC LIMIT 1))
WHERE 
    pi.PriceRank <= 10
ORDER BY 
    pi.p_retailprice DESC NULLS LAST;
