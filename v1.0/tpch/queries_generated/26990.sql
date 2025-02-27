WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        substr(s.s_comment, 1, 25) AS short_comment,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
), 
ExtensivePart AS (
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
        LENGTH(p.p_comment) AS comment_length,
        CHAR_LENGTH(p.p_name) AS name_length
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_clerk,
        CONCAT('Order by ', o.o_clerk, ' on ', to_char(o.o_orderdate, 'YYYY-MM-DD')) AS description
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    rp.s_suppkey, 
    rp.s_name, 
    ep.p_partkey, 
    ep.p_name, 
    fo.o_orderkey, 
    fo.description,
    (rp.s_acctbal + ep.p_retailprice) AS adjusted_price,
    ep.comment_length,
    ep.name_length
FROM 
    RankedSuppliers rp
JOIN 
    partsupp ps ON rp.s_suppkey = ps.ps_suppkey
JOIN 
    ExtensivePart ep ON ps.ps_partkey = ep.p_partkey
JOIN 
    FilteredOrders fo ON fo.o_orderkey = ps.ps_partkey % 10000
WHERE 
    rp.rn <= 3
ORDER BY 
    rp.s_nationkey, adjusted_price DESC;
