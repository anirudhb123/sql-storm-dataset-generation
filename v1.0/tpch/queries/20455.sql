
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_supplycost 
                     FROM partsupp ps 
                     WHERE ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) 
                                                FROM partsupp ps2 
                                                WHERE ps2.ps_availqty > 0))
), 

SupplierRegions AS (
    SELECT 
        s.s_name,
        n.n_name,
        r.r_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name, n.n_name, r.r_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 2
), 

HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
)

SELECT 
    sr.s_name,
    sr.n_name,
    sr.r_name,
    COUNT(DISTINCT hp.o_orderkey) AS high_value_order_count,
    AVG(hp.total_value) AS avg_high_value,
    STRING_AGG(DISTINCT rp.p_name || ' (Price: ' || rp.p_retailprice || ')', ', ') AS top_products
FROM 
    SupplierRegions sr
LEFT JOIN 
    HighValueOrders hp ON sr.total_parts = (SELECT COUNT(DISTINCT ps.ps_partkey) FROM partsupp ps)
LEFT JOIN 
    RankedParts rp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 0 
                                         OR ps.ps_availqty IS NULL)
GROUP BY 
    sr.s_name, sr.n_name, sr.r_name
ORDER BY 
    high_value_order_count DESC, avg_high_value DESC;
