WITH SupplierComments AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        CONCAT('Supplier Name: ', s.s_name, ', Address: ', s.s_address, ', Nation Key: ', s.s_nationkey, ', Comment: ', s.s_comment) AS full_comment
    FROM
        supplier s
),
PartComments AS (
    SELECT
        p.p_partkey,
        p.p_name,
        CONCAT('Part Name: ', p.p_name, ', Manufacturer: ', p.p_mfgr, ', Type: ', p.p_type, ', Comment: ', p.p_comment) AS full_comment
    FROM
        part p
),
OrdersSummary AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        s.full_comment AS supplier_comment,
        p.full_comment AS part_comment
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON l.l_partkey = p.p_partkey
)
SELECT
    os.o_orderkey,
    os.o_totalprice,
    LENGTH(os.supplier_comment) AS supplier_comment_length,
    LENGTH(os.part_comment) AS part_comment_length,
    SUBSTRING(os.supplier_comment, 1, 50) AS short_supplier_comment,
    SUBSTRING(os.part_comment, 1, 50) AS short_part_comment
FROM
    OrdersSummary os
WHERE
    CHAR_LENGTH(os.supplier_comment) > 100
ORDER BY
    os.o_orderkey DESC;
