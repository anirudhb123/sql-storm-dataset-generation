WITH RankedParts AS (
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
        p.p_retailprice IS NOT NULL AND 
        p.p_size BETWEEN 1 AND 20
),
TotalCustomerOrderValue AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_value,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierDetail AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COALESCE(SUM(td.total_value), 0) AS total_order_value,
    SUM(sd.total_available) AS available_parts,
    MAX(CASE WHEN rp.rn = 1 THEN rp.p_retailprice ELSE NULL END) AS highest_retail_price,
    STRING_AGG(DISTINCT rp.p_name, ', ') AS top_part_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    TotalCustomerOrderValue td ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = td.c_custkey)
LEFT JOIN 
    SupplierDetail sd ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = sd.s_suppkey)
LEFT JOIN 
    RankedParts rp ON rp.p_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost >= (SELECT AVG(ps_supplycost) FROM partsupp)))
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    SUM(sd.total_available) > 100 AND 
    COUNT(DISTINCT n.n_nationkey) < (SELECT COUNT(*) FROM nation) 
ORDER BY 
    total_order_value DESC NULLS LAST;
