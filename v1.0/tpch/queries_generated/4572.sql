WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) as SupplierRank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalOrders,
        COUNT(o.o_orderkey) AS OrderCount,
        MAX(o.o_orderdate) AS LastOrderDate
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS TotalQuantity,
        AVG(l.l_extendedprice) AS AvgPrice,
        COUNT(DISTINCT l.l_orderkey) AS OrderCount
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    cs.c_name,
    ps.p_name,
    ps.TotalQuantity,
    ps.AvgPrice,
    rs.s_name AS TopSupplier,
    rs.s_acctbal AS TopSupplierAcctBal,
    co.TotalOrders,
    co.OrderCount,
    co.LastOrderDate
FROM 
    PartStats ps
JOIN 
    RankedSuppliers rs ON ps.p_partkey = rs.ps_partkey AND rs.SupplierRank = 1
JOIN 
    CustomerOrders co ON co.OrderCount > 5
LEFT JOIN 
    nation n ON rs.s_suppkey = n.n_nationkey
WHERE 
    (rs.s_acctbal IS NOT NULL OR ps.TotalQuantity > 100)
    AND ps.AvgPrice > 20
ORDER BY 
    co.TotalOrders DESC, ps.AvgPrice DESC;
