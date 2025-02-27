WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS OrderRank
    FROM 
        orders o
),
CustomerTotalSpend AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpend
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS TotalAvailable
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ct.TotalSpend
    FROM 
        customer c
    JOIN 
        CustomerTotalSpend ct ON c.c_custkey = ct.c_custkey
    WHERE 
        ct.TotalSpend > 1000
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    c.c_name AS CustomerName,
    c.c_acctbal AS CustomerBalance,
    s.ps_partkey,
    sa.TotalAvailable,
    CASE 
        WHEN l.l_quantity > 100 THEN 'Bulk Order'
        ELSE 'Regular Order'
    END AS OrderType,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS CustomerOrderRank
FROM 
    RankedOrders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    SupplierAvailability sa ON l.l_partkey = sa.ps_partkey
JOIN 
    HighValueCustomers c ON o.o_custkey = c.c_custkey
WHERE 
    o.o_orderdate >= '2023-01-01' 
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 500)
ORDER BY 
    o.o_orderdate DESC,
    o.o_orderkey;
