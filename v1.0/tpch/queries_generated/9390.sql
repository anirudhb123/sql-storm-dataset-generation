WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate
    FROM 
        RankedOrders ro
    WHERE 
        ro.OrderRank <= 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        to.o_orderkey,
        to.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TopOrders to ON o.o_orderkey = to.o_orderkey
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
)
SELECT 
    co.c_name AS CustomerName,
    co.c_acctbal AS AccountBalance,
    to.o_totalprice AS OrderTotalPrice,
    sd.s_name AS SupplierName,
    sd.TotalSupplyCost AS SupplierTotalCost
FROM 
    CustomerOrders co
JOIN 
    lineitem li ON co.o_orderkey = li.l_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    supplier sd ON ps.ps_suppkey = sd.s_suppkey
WHERE 
    li.l_shipdate >= DATE '2022-01-01'
ORDER BY 
    co.c_acctbal DESC, to.o_totalprice DESC;
