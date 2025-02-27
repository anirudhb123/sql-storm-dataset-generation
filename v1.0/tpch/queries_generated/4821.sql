WITH NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
        SUM(s.s_acctbal) AS TotalAccountBalance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
PartSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity,
        AVG(ps.ps_supplycost) AS AverageSupplyCost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
OrderStats AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    ns.n_name,
    ns.SupplierCount,
    ns.TotalAccountBalance,
    ps.p_name,
    ps.TotalAvailableQuantity,
    ps.AverageSupplyCost,
    os.TotalSpent,
    os.OrderCount
FROM 
    NationSummary ns
FULL OUTER JOIN 
    PartSupplierStats ps ON ns.SupplierCount > 10
LEFT JOIN 
    OrderStats os ON 1 = 1
WHERE 
    ps.AverageSupplyCost IS NOT NULL 
    AND (os.TotalSpent > 500 OR os.TotalSpent IS NULL)
ORDER BY 
    ns.n_name, ps.p_name;
