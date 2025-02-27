
WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        REPLACE(REPLACE(p.p_comment, 'Supplier', ''), 'parts', '') AS sanitized_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_info
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey
),
CombinedData AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        sd.s_suppkey,
        sd.s_name,
        os.o_orderkey,
        os.line_count,
        os.total_extended_price,
        pd.comment_length,
        pd.sanitized_comment
    FROM 
        PartDetails pd
    JOIN 
        partsupp ps ON pd.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN 
        OrderSummary os ON os.o_orderkey IN (
            SELECT o.o_orderkey 
            FROM orders o 
            JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
            WHERE l.l_partkey = pd.p_partkey
        )
)
SELECT 
    p_name, 
    s_name, 
    SUM(total_extended_price) AS total_revenue,
    AVG(comment_length) AS avg_comment_length,
    COUNT(DISTINCT o_orderkey) AS number_of_orders
FROM 
    CombinedData
GROUP BY 
    p_name, s_name
ORDER BY 
    total_revenue DESC, avg_comment_length ASC;
