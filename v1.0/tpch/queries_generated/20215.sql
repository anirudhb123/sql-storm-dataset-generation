WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_name) AS row_num
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Undefined Size'
            WHEN p.p_size < 10 THEN 'Small Parts'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium Parts'
            ELSE 'Large Parts'
        END AS size_category
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), 
AggregatedLineItems AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_count,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey, 
    p.p_name,
    coalesce(s.s_name, 'No Supplier') AS supplier_name,
    p.p_retailprice,
    hv.size_category,
    COALESCE(ali.total_revenue, 0) AS total_revenue,
    ali.line_count AS total_line_items,
    s_rank.rank_acctbal
FROM 
    HighValueParts hv
LEFT JOIN 
    partsupp ps ON hv.p_partkey = ps.ps_partkey
LEFT JOIN 
    RankedSuppliers s_rank ON ps.ps_suppkey = s_rank.s_suppkey AND s_rank.rank_acctbal = 1
LEFT JOIN 
    AggregatedLineItems ali ON hv.p_partkey = ali.l_partkey
WHERE 
    (s_rank.s_suppkey IS NULL OR s_rank.rank_acctbal <= 3)
    AND (p.p_retailprice IS NOT NULL AND p.p_retailprice <> 0)
ORDER BY 
    total_revenue DESC, p.p_name ASC
LIMIT 
    100;
