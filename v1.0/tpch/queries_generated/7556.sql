WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as OrderRanking
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
),
TopOrders AS (
    SELECT 
        r.r_name,
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.c_acctbal
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.OrderRanking <= 5
),
PartSupplies AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailable,
        SUM(ps.ps_supplycost) AS TotalCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.r_name AS Region,
    to.o_orderkey AS OrderID,
    to.o_orderdate AS OrderDate,
    to.o_totalprice AS TotalPrice,
    to.c_name AS CustomerName,
    to.c_acctbal AS CustomerBalance,
    ps.TotalAvailable AS AvailableSupply,
    ps.TotalCost AS SupplyCost
FROM 
    TopOrders to
JOIN 
    PartSupplies ps ON ps.ps_partkey IN (SELECT ps_partkey FROM lineitem WHERE l_orderkey = to.o_orderkey)
JOIN 
    region r ON to.r_name = r.r_name
ORDER BY 
    to.o_orderdate DESC, 
    to.o_totalprice DESC;
