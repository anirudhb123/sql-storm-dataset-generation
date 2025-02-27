WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS RankByBalance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS TotalSpent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS RankBySpending
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_nationkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        COUNT(*) AS SupplyCount,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    ps.p_partkey,
    ps.SupplyCount,
    ps.AvgSupplyCost,
    cs.c_custkey,
    cs.TotalSpent,
    rs.s_name,
    rs.s_acctbal
FROM 
    PartStats ps
LEFT JOIN 
    RankedSuppliers rs ON rs.RankByBalance = 1
LEFT JOIN 
    CustomerOrders cs ON cs.RankBySpending <= 5
WHERE 
    ps.AvgSupplyCost IS NOT NULL AND 
    (rs.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL) OR 
    EXISTS (SELECT 1 FROM lineitem l WHERE l.l_receivedate IS NOT NULL AND l.l_partkey = ps.p_partkey))
ORDER BY 
    ps.AvgSupplyCost DESC, 
    cs.TotalSpent DESC 
LIMIT 100;
