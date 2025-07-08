
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_size
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 100)
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(l.l_orderkey) AS TotalLineItems
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
), NationWithComments AS (
    SELECT 
        n.n_name, 
        n.n_comment,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
        n.n_nationkey
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, n.n_comment
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 0
)

SELECT 
    ns.n_name,
    ns.n_comment,
    COALESCE(rs.SupplierRank, 0) AS SupplierRank,
    ps.p_name,
    os.TotalRevenue,
    ns.SupplierCount
FROM 
    NationWithComments ns
LEFT JOIN 
    RankedSuppliers rs ON ns.n_nationkey = rs.s_nationkey AND rs.SupplierRank = 1
LEFT JOIN 
    FilteredParts ps ON ps.p_partkey = (
        SELECT p2.p_partkey
        FROM part p2
        WHERE p2.p_retailprice > (
            SELECT AVG(p3.p_retailprice) FROM part p3 WHERE p3.p_size = 10
        )
        ORDER BY RANDOM()
        LIMIT 1 
    )
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = (
        SELECT o2.o_orderkey
        FROM orders o2
        WHERE o2.o_totalprice > 5000 AND o2.o_orderstatus = 'O'
        ORDER BY RANDOM()
        LIMIT 1 
    )
WHERE 
    ns.SupplierCount IS NOT NULL
ORDER BY 
    ns.n_name, os.TotalRevenue DESC;
