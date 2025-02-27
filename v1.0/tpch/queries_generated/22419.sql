WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS RankCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSpent
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_name
),
UnfulfilledOrders AS (
    SELECT 
        o.o_orderkey, 
        (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = o.o_orderkey AND l.l_returnflag = 'R') AS ReturnedItems
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        COUNT(l.l_orderkey) < 1 OR COUNT(l.l_orderkey) = ReturnedItems
),
FinalOutput AS (
    SELECT 
        co.c_name, 
        rs.s_name, 
        co.TotalSpent, 
        (CASE WHEN co.TotalSpent IS NULL THEN 'No Orders' ELSE 'Orders Made' END) AS OrderStatus
    FROM 
        CustomerOrders co
    LEFT JOIN 
        RankedSuppliers rs ON co.o_orderkey IN (SELECT DISTINCT o.o_orderkey FROM orders o)
    WHERE 
        co.TotalSpent > 1000 AND 
        rs.RankCost < 3
    ORDER BY 
        co.TotalSpent DESC
)
SELECT 
    r.r_name AS Region, 
    fo.c_name AS CustomerName, 
    fo.s_name AS SupplierName, 
    fo.TotalSpent, 
    CURRENT_DATE - MAX(co.o_orderdate) AS DaysSinceLastOrder
FROM 
    FinalOutput fo
LEFT JOIN 
    nation n ON fo.c_custkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name, fo.c_name, fo.s_name, fo.TotalSpent
HAVING 
    DaysSinceLastOrder > 30 OR COUNT(fo.s_name) IS NULL
ORDER BY 
    RAND() LIMIT 5;
