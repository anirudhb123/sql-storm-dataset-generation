WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 100000
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        COUNT(*) AS ItemCount,
        AVG(l.l_extendedprice) AS AvgPrice,
        SUM(l.l_discount) AS TotalDiscount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
OrderShippingDates AS (
    SELECT 
        o.o_orderkey,
        MIN(l.l_shipdate) AS FirstShipDate,
        MAX(l.l_shipdate) AS LastShipDate
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ns.r_name AS SupplierNation,
    COUNT(DISTINCT r.s_suppkey) AS SupplierCount,
    SUM(oi.ItemCount) AS TotalItemsOrdered,
    COALESCE(SUM(c.TotalSpent), 0) AS TotalSpentByCustomers,
    MAX(oi.AvgPrice) AS MaxAveragePrice,
    AVG(oi.TotalDiscount) AS AvgDiscount
FROM 
    RankedSuppliers r
FULL OUTER JOIN 
    LineItemStats oi ON r.s_suppkey = oi.l_orderkey
FULL OUTER JOIN 
    HighValueCustomers c ON r.s_suppkey = c.c_custkey
LEFT JOIN 
    nation ns ON r.s_nationkey = ns.n_nationkey
WHERE 
    ns.r_comment IS NOT NULL
GROUP BY 
    ns.r_name
HAVING 
    COUNT(DISTINCT r.s_suppkey) > 5
ORDER BY 
    SupplierNation;
