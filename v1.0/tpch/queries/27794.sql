
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        CONCAT(s.s_name, ' - ', s.s_address) AS SupplierDetails,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS RankPerNation,
        s.s_nationkey
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_type, 
        p.p_retailprice,
        SUBSTRING(p.p_comment, 1, 10) AS ShortComment,
        CASE 
            WHEN p.p_container LIKE '%BOX%' THEN 'Boxed'
            WHEN p.p_container LIKE '%JAR%' THEN 'Jarred'
            ELSE 'Other' 
        END AS ContainerType
    FROM 
        part p
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalMetrics AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        COALESCE(SUM(l.l_quantity), 0) AS TotalQuantitySold,
        COALESCE(SUM(l.l_extendedprice), 0) AS TotalRevenue
    FROM 
        partsupp ps
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)

SELECT 
    rs.SupplierDetails,
    pd.p_name,
    pd.ContainerType,
    co.OrderCount,
    co.TotalSpent,
    fm.TotalQuantitySold,
    fm.TotalRevenue,
    pd.ShortComment
FROM 
    RankedSuppliers rs
JOIN 
    PartDetails pd ON rs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pd.p_partkey LIMIT 1)
JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = pd.p_partkey LIMIT 1)
JOIN 
    FinalMetrics fm ON fm.ps_partkey = pd.p_partkey AND fm.ps_suppkey = rs.s_suppkey
WHERE 
    rs.RankPerNation <= 3
ORDER BY 
    rs.s_nationkey, fm.TotalRevenue DESC;
