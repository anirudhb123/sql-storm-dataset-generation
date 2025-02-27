WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        LENGTH(s.s_comment) AS comment_length,
        REPLACE(s.s_comment, ' ', '') AS comment_nospace
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT(p.p_name, ' ', p.p_type, ' ', p.p_brand) AS full_description
    FROM 
        part p
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items,
        CONCAT('Order ', o.o_orderkey, ' placed on ', TO_CHAR(o.o_orderdate, 'YYYY-MM-DD')) AS order_description
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_orderdate
),
FinalBenchmark AS (
    SELECT 
        si.s_name,
        si.nation_name,
        pd.p_name,
        pd.full_description,
        os.total_revenue,
        os.total_items,
        CONCAT(si.s_name, ' from ', si.nation_name, ' supplied ', pd.p_name) AS supplier_part_info
    FROM 
        SupplierInfo si
    JOIN 
        PartDetails pd ON si.s_suppkey = pd.p_partkey
    JOIN 
        OrderSummary os ON pd.p_partkey = os.o_custkey
)
SELECT 
    supplier_part_info,
    total_revenue,
    total_items,
    comment_length,
    CONCAT('Length of Comments: ', comment_length) AS comment_info
FROM 
    FinalBenchmark
WHERE 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
