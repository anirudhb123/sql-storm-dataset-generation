WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
),
supplier_region AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
),
order_details AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        MAX(l.l_tax) AS max_tax,
        COUNT(l.l_orderkey) AS items_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2021-01-01' AND o.o_orderdate < '2022-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_mfgr,
    sr.r_name AS supplier_region,
    od.total_price,
    od.max_tax,
    od.items_count
FROM 
    ranked_parts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    supplier_region sr ON s.s_suppkey = sr.s_suppkey
JOIN 
    order_details od ON ps.ps_partkey = od.o_orderkey
WHERE 
    (sr.nation_count > 1 OR sr.nation_count IS NULL)
    AND rn = 1
    AND (rp.p_retailprice IS NOT NULL OR rp.p_size < 15)
ORDER BY 
    od.total_price DESC, 
    rp.p_name ASC 
FETCH FIRST 10 ROWS ONLY
UNION ALL
SELECT
    -1 AS p_partkey,
    'Aggregate Total' AS p_name,
    'N/A' AS p_mfgr,
    'N/A' AS supplier_region,
    SUM(total_price) AS total_price,
    NULL AS max_tax,
    NULL AS items_count
FROM 
    order_details
WHERE 
    (SELECT COUNT(*) FROM lineitem WHERE l_returnflag = 'R') > 0
HAVING 
    COUNT(*) > 5
;
