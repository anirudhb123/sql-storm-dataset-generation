WITH MatchingParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supplycost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
        p.p_size, p.p_container, p.p_retailprice, p.p_comment
    HAVING 
        SUM(ps.ps_supplycost) > 10000 AND COUNT(DISTINCT ps.ps_suppkey) > 3
)
SELECT 
    mp.p_partkey,
    mp.p_name,
    mp.p_brand,
    mp.p_type,
    mp.p_retailprice,
    mp.supplier_count,
    mp.total_supplycost,
    mp.suppliers,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    MatchingParts mp
JOIN 
    partsupp ps ON mp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    mp.p_partkey, mp.p_name, mp.p_brand, mp.p_type, 
    mp.p_retailprice, mp.supplier_count, mp.total_supplycost, 
    mp.suppliers, r.r_name, n.n_name
ORDER BY 
    mp.total_supplycost DESC, mp.p_name ASC;
