WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name AS region_name
    FROM 
        RankedSuppliers s
    JOIN 
        region r ON s.nation_name = r.r_name
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
LowStockParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) < 50
)
SELECT 
    p.p_name,
    s.s_name,
    COALESCE(LAG(l.l_quantity) OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber), 0) AS previous_quantity,
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'Supplier Missing'
        ELSE 'Supplier Present'
    END AS supplier_status,
    p.total_availqty / NULLIF(s.s_acctbal, 0) AS stock_to_balance_ratio
FROM 
    LowStockParts p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighValueSuppliers s ON l.l_suppkey = s.s_suppkey
WHERE 
    (s.s_acctbal IS NOT NULL OR l.l_orderkey IS NULL)
ORDER BY 
    supplier_status DESC, stock_to_balance_ratio ASC 
LIMIT 100
UNION ALL
SELECT 
    'Aggregate' AS p_name,
    NULL AS s_name,
    SUM(l.l_quantity) AS previous_quantity,
    'Total Sum' AS supplier_status,
    SUM(p.total_availqty) / NULLIF(SUM(s.s_acctbal), 0) AS stock_to_balance_ratio
FROM 
    LowStockParts p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    HighValueSuppliers s ON l.l_suppkey = s.s_suppkey
HAVING 
    SUM(l.l_quantity) > 0;
