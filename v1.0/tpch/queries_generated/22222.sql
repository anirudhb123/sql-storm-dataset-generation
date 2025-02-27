WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS OrderCount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
        AND c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2 
            WHERE c2.c_mktsegment = c.c_mktsegment
        )
    GROUP BY 
        c.c_custkey
),
FinalOutput AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS TotalSales,
        COUNT(DISTINCT cs.c_custkey) AS UniqueCustomers,
        COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS ReturnOrders,
        MAX(ps.ps_supplycost) AS MaxSupplyCost
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey
    LEFT JOIN 
        FilteredCustomers cs ON cs.OrderCount > 0
    WHERE 
        p.p_size IS NOT NULL
        AND p.p_retailprice > (
            SELECT 
                AVG(p2.p_retailprice) 
            FROM 
                part p2 
            WHERE 
                p2.p_type LIKE 'PROD%'
        )
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    fo.p_partkey,
    fo.p_name,
    fo.TotalSales,
    fo.UniqueCustomers,
    fo.ReturnOrders,
    fo.MaxSupplyCost
FROM 
    FinalOutput fo
JOIN 
    nation n ON n.n_nationkey IN (SELECT DISTINCT s.s_nationkey FROM supplier s JOIN RankedSuppliers rs ON rs.s_suppkey = s.s_suppkey)
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    fo.TotalSales > 0
ORDER BY 
    r.r_name, fo.TotalSales DESC;
