WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(DISTINCT l.l_orderkey) AS LineCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
CustomerAggregates AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(o.TotalRevenue) AS AvgRevenue,
        SUM(o.LineCount) AS TotalLineCount,
        RANK() OVER (ORDER BY AVG(o.TotalRevenue) DESC) AS CustomerRank
    FROM 
        customer c
    JOIN 
        RecentOrders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    rs.s_name,
    ca.c_name,
    ca.AvgRevenue,
    rs.TotalSupplyCost,
    COALESCE(rs.SupplierRank, 0) AS SupplierRank,
    COALESCE(ca.CustomerRank, 0) AS CustomerRank
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.ps_partkey
LEFT JOIN 
    CustomerAggregates ca ON ca.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = 'USA'
        )
        LIMIT 1
    )
WHERE 
    p.p_size = (
        SELECT MAX(p2.p_size) 
        FROM part p2 
        WHERE p2.p_type = p.p_type
    )
ORDER BY 
    p.p_partkey, rs.TotalSupplyCost DESC, ca.AvgRevenue DESC;
