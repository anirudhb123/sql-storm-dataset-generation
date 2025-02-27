
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
SparseRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS NationCount
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT n.n_nationkey) < 2
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent,
        AVG(o.o_totalprice) AS AvgSpent,
        COUNT(o.o_orderkey) AS OrderCount,
        CASE 
            WHEN AVG(o.o_totalprice) > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS CustomerType
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS RegionName,
    n.n_name AS NationName,
    cs.c_custkey AS CustomerKey,
    cs.TotalSpent,
    rk.TotalSupplyCost,
    CASE 
        WHEN cs.TotalSpent IS NULL THEN 'No Orders' 
        WHEN cs.CustomerType = 'High Value' AND rk.rank <= 3 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS CustomerStatus
FROM 
    SparseRegions r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey AND c.c_acctbal IS NOT NULL
    )
LEFT JOIN 
    RankedSuppliers rk ON rk.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE l.l_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o 
            WHERE o.o_custkey = cs.c_custkey
        ) 
        GROUP BY ps.ps_suppkey 
        ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC 
        LIMIT 1
    )
WHERE 
    r.NationCount IS NULL
    OR (rk.TotalSupplyCost IS NOT NULL AND rk.TotalSupplyCost > 0)
ORDER BY 
    r.r_name, CustomerStatus DESC, cs.TotalSpent DESC;
