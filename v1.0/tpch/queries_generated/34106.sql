WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey, 
        c.c_name,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        0 AS Level
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'  -- Fully filled orders
    UNION ALL
    SELECT 
        oh.o_orderkey,
        c.c_name,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        Level + 1
    FROM 
        OrderHierarchy oh
    JOIN 
        orders o ON o.o_orderkey = oh.o_orderkey AND oh.Level < 5  -- Limiting recursion depth
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_partkey) AS UniqueParts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    oh.o_orderkey,
    oh.c_name,
    oh.o_orderdate,
    oh.o_totalprice,
    oh.o_orderstatus,
    COALESCE(lia.TotalRevenue, 0) AS TotalLineItemRevenue,
    COALESCE(lia.UniqueParts, 0) AS DistinctLineItems,
    si.s_name,
    si.PartCount,
    si.TotalCost
FROM 
    OrderHierarchy oh
LEFT JOIN 
    LineItemAggregates lia ON oh.o_orderkey = lia.l_orderkey
LEFT JOIN 
    SupplierInfo si ON si.PartCount > 0
WHERE 
    oh.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (si.TotalCost IS NULL OR si.TotalCost > 10000)
ORDER BY 
    oh.o_orderdate DESC, 
    oh.o_orderkey ASC;
