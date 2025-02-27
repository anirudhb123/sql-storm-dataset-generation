WITH SupplierStatistics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniqueParts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_customerkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate < CURRENT_DATE
    GROUP BY 
        o.o_orderkey, o.o_customerkey
),
EnhancedCustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'No Balance'
            WHEN c.c_acctbal < 0 THEN 'Negative Balance'
            ELSE 'Positive Balance'
        END AS BalanceStatus
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL 
        OR (c.c_acctbal IS NULL AND EXISTS (SELECT 1 FROM orders o WHERE o.o_custkey = c.c_custkey))
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        ROW_NUMBER() OVER (ORDER BY TotalCost DESC) AS Rank
    FROM 
        SupplierStatistics s
)
SELECT 
    e.c_custkey,
    e.c_name,
    e.BalanceStatus,
    r.s_name AS TopSupplier,
    r.TotalCost
FROM 
    EnhancedCustomerInfo e
LEFT JOIN 
    RankedSuppliers r ON e.c_custkey = (
        SELECT 
            o.o_customerkey 
        FROM 
            OrderDetails o
        WHERE 
            o.TotalRevenue = (SELECT MAX(TotalRevenue) FROM OrderDetails od WHERE od.o_customerkey = e.c_custkey)
    )
ORDER BY 
    e.c_acctbal DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
