WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) AS SupplyRank,
        SUM(ps_availqty) OVER (PARTITION BY s.s_suppkey) AS TotalAvailable
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c_acctbal DESC) AS CustomerRank
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer) 
        AND c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS LineCount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ns.n_name,
    ps.p_name,
    COUNT(DISTINCT l.l_orderkey) AS OrdersCount,
    COALESCE(SUM(CASE WHEN ls.l_returnflag = 'R' THEN 1 ELSE 0 END), 0) AS ReturnsCount,
    (SELECT COUNT(*) FROM HighValueCustomers) AS TotalHighValueCustomers,
    AVG(COALESCE(rd.TotalAvailable, 0)) AS AvgAvailableQty
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    OrdersDetails od ON l.l_orderkey = od.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.SupplyRank = 1
LEFT JOIN 
    lineitem ls ON l.l_orderkey = ls.l_orderkey
WHERE 
    ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
    AND ns.n_name IS NOT NULL
GROUP BY 
    ns.n_name, ps.p_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY 
    AvgAvailableQty DESC, ReturnsCount DESC;
