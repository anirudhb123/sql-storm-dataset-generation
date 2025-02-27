WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.n_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        SUM(ps.ps_availqty) > 0
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        LAG(o.o_totalprice) OVER (ORDER BY o.o_orderdate) AS previous_totalprice
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    DISTINCT p.p_name, 
    r.r_name, 
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    p.p_retailprice,
    CASE 
        WHEN o.previous_totalprice IS NULL THEN 'First Order'
        WHEN o.previous_totalprice < o.o_totalprice THEN 'Increased'
        ELSE 'Decreased'
    END AS price_trend
FROM 
    FilteredParts p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN 
    nation n ON rs.n_nationkey = n.n_nationkey
LEFT JOIN 
    RecentOrders o ON p.p_partkey = ANY (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
WHERE 
    p.p_retailprice BETWEEN 
        (SELECT AVG(total_available * p_retailprice) FROM FilteredParts) 
        AND 
        (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    CASE WHEN price_trend = 'Increased' THEN 1 ELSE 2 END,
    p.p_retailprice DESC;
