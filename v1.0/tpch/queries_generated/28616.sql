WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) as rn
    FROM 
        part p
), 
ExtendedSupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS country,
        CONCAT(s.s_name, ' ', s.s_address) AS full_info,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_partkey) AS unique_parts_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_retailprice,
    esi.full_info,
    od.customer_name,
    od.o_orderdate,
    od.total_quantity,
    od.unique_parts_count,
    STRING_AGG(CONCAT(esi.country, ': ', CONCAT('Comment Length = ', esi.comment_length)), '; ') AS supplier_info
FROM 
    RankedParts rp
LEFT JOIN 
    ExtendedSupplierInfo esi ON esi.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
WHERE 
    rp.rn <= 5
GROUP BY 
    rp.p_partkey, rp.p_name, rp.p_retailprice, esi.full_info, od.customer_name, od.o_orderdate, od.total_quantity, od.unique_parts_count
ORDER BY 
    rp.p_retailprice DESC, total_quantity DESC;
