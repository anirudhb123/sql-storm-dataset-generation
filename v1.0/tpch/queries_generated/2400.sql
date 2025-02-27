WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT p.p_partkey) AS UniquePartsSupplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_orderkey) AS LineItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    ns.n_name AS Nation,
    ns.r_name AS Region,
    ss.s_name AS Supplier,
    ss.TotalSupplyCost,
    os.TotalRevenue,
    os.LineItemCount,
    ROW_NUMBER() OVER (PARTITION BY ns.n_nationkey ORDER BY ss.TotalSupplyCost DESC) AS SupplierRank,
    CASE 
        WHEN os.TotalRevenue IS NULL THEN 'No Orders'
        ELSE CONCAT('Total Revenue: ', FORMAT(os.TotalRevenue, 'C'))
    END AS RevenueStatement
FROM 
    SupplierStats ss
LEFT JOIN 
    OrderSummary os ON ss.s_suppkey = os.o_orderkey
JOIN 
    NationRegion ns ON ss.s_nationkey = ns.n_nationkey
WHERE 
    ss.UniquePartsSupplied > 5
ORDER BY 
    ns.r_name, ss.TotalSupplyCost DESC;
