WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT('Part Name: ', p.p_name, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type) AS full_description
    FROM 
        part p
),
RelevantSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        LENGTH(s.s_comment) AS supplier_comment_length,
        s.s_comment || ' - Verified Supplier' AS verified_comment
    FROM 
        supplier s
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice) AS total_extended_price,
        o.o_orderdate,
        o.o_comment,
        UPPER(o.o_comment) AS upper_comment
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, o.o_comment
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.full_description,
    rs.s_name AS supplier_name,
    os.o_orderkey,
    os.line_item_count,
    os.total_extended_price,
    os.upper_comment,
    CAST(pd.comment_length AS VARCHAR) || ' | ' || CAST(rs.supplier_comment_length AS VARCHAR) AS combined_comment_lengths
FROM 
    PartDetails pd
JOIN 
    RelevantSuppliers rs ON pd.p_partkey = rs.s_nationkey
JOIN 
    OrderSummary os ON os.line_item_count > 1
WHERE 
    pd.p_retailprice > 100.00
ORDER BY 
    pd.p_name, rs.s_name, os.o_orderdate DESC;
