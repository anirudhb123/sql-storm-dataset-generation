WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        o.o_orderdate,
        COUNT(DISTINCT l.l_partkey) AS UniqueParts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
    HAVING 
        TotalRevenue > 10000
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(hvo.TotalRevenue), 0) AS TotalSpent,
        COUNT(hvo.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        HighValueOrders hvo ON c.c_custkey = hvo.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        (ps.ps_supplycost * ps.ps_availqty) AS TotalValue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    AVG(cu.OrderCount) AS AvgOrderCount,
    ps.p_name,
    SUM(ps.TotalValue) AS TotalPartValue,
    RANK() OVER (ORDER BY SUM(ps.TotalValue) DESC) AS PartRank
FROM 
    CustomerOrderInfo cu
JOIN 
    orders o ON cu.c_custkey = o.o_custkey
LEFT JOIN 
    PartSupplierInfo ps ON ps.ps_supplycost < 100
WHERE 
    cu.TotalSpent > 5000
GROUP BY 
    c.c_name, ps.p_name
HAVING 
    TotalOrders > 5 AND PartRank <= 10
ORDER BY 
    TotalPartValue DESC, c.c_name ASC;
