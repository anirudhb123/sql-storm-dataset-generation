WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
), 
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'UNKNOWN'
            WHEN p.p_size < 10 THEN 'SMALL'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'MEDIUM'
            ELSE 'LARGE'
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), 
AggregatedLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(*) AS total_items
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(ali.total_sales) AS total_revenue,
    STRING_AGG(DISTINCT fp.size_category, ', ') AS size_categories,
    MAX(fs.s_acctbal) AS highest_supplier_balance
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    AggregatedLineItems ali ON ali.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers fs ON fs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN 
        (SELECT p.p_partkey FROM FilteredParts p LIMIT 1)
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 1)
WHERE 
    o.o_orderstatus <> 'F' AND
    c.c_acctbal IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(ali.total_sales) > 10000 AND 
    COUNT(DISTINCT o.o_orderkey) >= 5
ORDER BY 
    total_revenue DESC NULLS LAST;
