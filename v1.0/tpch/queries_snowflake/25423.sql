
WITH RankedParts AS (
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
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    s.s_name AS supplier,
    pp.p_name AS part_name,
    pp.p_brand AS part_brand,
    pp.p_type AS part_type,
    pp.p_retailprice AS part_price,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_orders_value,
    LISTAGG(DISTINCT c.c_comment, ', ') AS customer_comments,
    LISTAGG(DISTINCT pp.p_comment, '; ') AS part_comments
FROM 
    RankedParts pp
JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON pp.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    pp.rank <= 5
GROUP BY 
    r.r_name, n.n_name, s.s_name, pp.p_name, pp.p_brand, pp.p_type, pp.p_retailprice
ORDER BY 
    region, nation, supplier, part_name;
