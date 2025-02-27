WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2022-01-01'
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
PartsSupply AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    c.c_name AS TopCustomer,
    o.o_totalprice AS HighestOrderPrice,
    ps.TotalAvailableQuantity,
    ps.AvgSupplyCost
FROM 
    part p
JOIN 
    RankedOrders o ON p.p_partkey = o.o_orderkey
JOIN 
    TopCustomers c ON o.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = c.c_custkey)
JOIN 
    PartsSupply ps ON p.p_partkey = ps.ps_partkey
WHERE 
    o.OrderRank <= 5
ORDER BY 
    o.o_orderdate DESC, o.o_totalprice DESC;
