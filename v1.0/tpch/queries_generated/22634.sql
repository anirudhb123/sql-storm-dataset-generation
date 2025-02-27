WITH RankedSuppliers AS (
    SELECT 
        ps.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        DENSE_RANK() OVER (ORDER BY c.c_acctbal DESC) AS BalanceRank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL)
),
EligibleOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS OrderNum
    FROM 
        orders o
    WHERE 
        o.o_totalprice IS NOT NULL
),
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS ItemCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        lineitem l 
    WHERE 
        l.l_shipdate <= '2023-10-31' 
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name AS Region, 
    ns.n_name AS Nation,
    COUNT(DISTINCT hc.c_custkey) AS HighValueCustomerCount,
    SUM(COALESCE(al.TotalRevenue, 0)) AS TotalRevenueGenerated,
    SUM(pr.TotalSupplyCost) AS TotalSupplierCost
FROM 
    region r
JOIN 
    nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN 
    HighValueCustomers hc ON ns.n_nationkey = hc.c_nationkey
LEFT JOIN 
    EligibleOrders eo ON hc.c_custkey = eo.o_custkey AND eo.OrderNum <= 5
LEFT JOIN 
    AggregatedLineItems al ON eo.o_orderkey = al.l_orderkey
LEFT JOIN 
    RankedSuppliers pr ON ns.n_nationkey = pr.n_nationkey AND pr.SupplierRank <= 3
GROUP BY 
    r.r_name, ns.n_name
HAVING 
    COUNT(DISTINCT hc.c_custkey) > 0 AND SUM(pr.TotalSupplyCost) IS NOT NULL
ORDER BY 
    TotalRevenueGenerated DESC, Region, Nation;
