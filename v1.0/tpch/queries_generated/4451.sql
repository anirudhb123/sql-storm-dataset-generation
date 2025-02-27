WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalOrderValue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(co.TotalOrderValue, 0) AS TotalValue,
    COALESCE(su.TotalSupplyCost, 0) AS TotalSupplyCost,
    NR.r_name AS Region,
    RANK() OVER (ORDER BY c.c_acctbal DESC) AS CustomerRank
FROM 
    customer c
LEFT JOIN 
    CustomerOrders co ON c.c_custkey = co.c_custkey
LEFT JOIN 
    SupplierDetails su ON su.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders o WHERE o.OrderRank <= 10)))
LEFT JOIN 
    NationRegion NR ON c.c_nationkey = NR.n_nationkey
WHERE 
    c.c_acctbal IS NOT NULL
ORDER BY 
    CustomerRank, TotalValue DESC;
