WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderMetrics AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(l.l_orderkey) AS LineItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' 
        AND o.o_orderdate <= '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
AggregateMetrics AS (
    SELECT 
        s.s_name,
        COALESCE(o.LineItemCount, 0) AS LineItemCount,
        COALESCE(c.TotalSpent, 0) AS CustomerTotalSpent,
        s.TotalSupplyCost,
        ROW_NUMBER() OVER (ORDER BY s.TotalSupplyCost DESC) AS SupplyRank
    FROM 
        SupplierStats s
    LEFT JOIN 
        OrderMetrics o ON o.TotalRevenue > 10000
    LEFT JOIN 
        CustomerSpending c ON c.TotalSpent > 5000
)
SELECT 
    a.s_name,
    a.LineItemCount,
    a.CustomerTotalSpent,
    a.TotalSupplyCost,
    CASE 
        WHEN a.LineItemCount > 5 THEN 'High Activity'
        ELSE 'Low Activity'
    END AS ActivityStatus
FROM 
    AggregateMetrics a
WHERE 
    a.SupplyRank <= 10
ORDER BY 
    a.TotalSupplyCost DESC
LIMIT 10;
