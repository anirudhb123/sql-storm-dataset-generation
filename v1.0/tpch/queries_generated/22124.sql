WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND l.l_shipdate < CURRENT_DATE
    GROUP BY 
        s.s_suppkey, s.s_name, ps.partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        RankedSuppliers s
    WHERE 
        s.supplier_rank = 1
),
DynamicRegion AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    WHERE 
        r.r_name LIKE 'EU%' OR r.r_name IS NULL
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    MAX(l.l_extendedprice) AS max_price,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returns,
    d.nation_count,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    TopSuppliers s ON l.l_suppkey = s.s_suppkey
INNER JOIN 
    DynamicRegion d ON l.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
WHERE 
    p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost > 100)
    OR (p.p_container IS NULL AND p.p_retailprice IS NOT NULL)
    AND l.l_discount NOT BETWEEN 0.10 AND 0.20
GROUP BY 
    p.p_name, p.p_brand, p.p_type, d.nation_count, s.s_name
HAVING 
    COUNT(l.l_orderkey) > 5
ORDER BY 
    max_price DESC, total_returns ASC NULLS LAST;
