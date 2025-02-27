WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 

TopSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT rs.s_suppkey) AS TotalSuppliers,
        SUM(rs.s_acctbal) AS TotalAcctBal
    FROM 
        region r
    LEFT JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.s_suppkey % (SELECT COUNT(DISTINCT n_nationkey) FROM nation)
    GROUP BY 
        r.r_name
), 

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS NumberOfOrders,
        COALESCE(SUM(o.o_totalprice), 0) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 

OrderDetails AS (
    SELECT 
        o.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_discount,
        l.l_extendedprice,
        (l.l_extendedprice * (1 - l.l_discount)) AS NetPrice
    FROM 
        lineitem l 
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
), 

SuppliersWithItemCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS UniqueSuppliersForPart
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    r.r_name AS RegionName,
    co.NumberOfOrders,
    co.TotalSpent,
    t.TotalSuppliers,
    t.TotalAcctBal,
    SUM(od.NetPrice) AS TotalRevenue,
    SUM(CASE WHEN od.l_quantity > 100 THEN 1 ELSE 0 END) AS HighQuantityOrders,
    COUNT(DISTINCT swic.ps_partkey) AS UniqueParts,
    STRING_AGG(DISTINCT COALESCE(s.s_name, 'Unknown Supplier'), ', ') AS SupplierNames
FROM 
    TopSuppliers t
JOIN 
    CustomerOrders co ON t.r_name = (SELECT r_name FROM region WHERE r_regionkey = co.c_custkey % (SELECT COUNT(*) FROM region))
LEFT JOIN 
    OrderDetails od ON od.l_partkey IN (SELECT ps_partkey FROM SuppliersWithItemCounts swic WHERE swic.UniqueSuppliersForPart > 1)
LEFT JOIN 
    supplier s ON s.s_suppkey = od.l_suppkey
GROUP BY 
    r.r_name, co.NumberOfOrders, co.TotalSpent, t.TotalSuppliers, t.TotalAcctBal
HAVING 
    SUM(od.NetPrice) > AVG(co.TotalSpent) OR COUNT(DISTINCT swic.ps_partkey) >= 5
ORDER BY 
    r.r_name, co.TotalSpent DESC
LIMIT 10
OFFSET (SELECT COUNT(*) FROM customer) % 10;
