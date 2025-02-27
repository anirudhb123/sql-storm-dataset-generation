WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(ps.ps_partkey) AS PartCount
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2022-01-01'
        AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_name AS NationName,
        c.c_acctbal
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        c.c_acctbal > (
            SELECT AVG(c_sub.c_acctbal) 
            FROM customer c_sub 
            WHERE c_sub.c_mktsegment = 'BUILDING'
        )
)
SELECT 
    ci.c_name AS CustomerName,
    ci.NationName,
    os.TotalRevenue,
    ss.s_name AS SupplierName,
    ss.TotalSupplyCost,
    DENSE_RANK() OVER (PARTITION BY ci.NationName ORDER BY os.TotalRevenue DESC) AS RevenueRank
FROM 
    CustomerInfo ci
LEFT JOIN 
    OrderSummary os ON ci.c_custkey = os.o_custkey
LEFT JOIN 
    SupplierStats ss ON ss.PartCount > 5
WHERE 
    (ci.NationName IS NOT NULL AND os.TotalRevenue IS NOT NULL)
ORDER BY 
    ci.NationName, RevenueRank;
