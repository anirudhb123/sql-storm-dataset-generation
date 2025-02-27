WITH SplitComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_comment,
        SPLIT_PART(s.s_comment, ' ', 1) AS first_word,
        SPLIT_PART(s.s_comment, ' ', 2) AS second_word,
        SPLIT_PART(s.s_comment, ' ', 3) AS third_word
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        LENGTH(p.p_name) AS name_length,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS short_comment
    FROM 
        part p
),
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    s.s_name,
    p.p_name,
    pd.name_length,
    pd.short_comment,
    os.line_item_count,
    os.total_extended_price,
    sc.first_word,
    sc.second_word,
    sc.third_word,
    r.r_name AS supplier_region
FROM 
    SplitComments sc
JOIN 
    supplier s ON s.s_suppkey = sc.s_suppkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    PartDetails pd ON p.p_partkey = pd.p_partkey
JOIN 
    orders o ON o.o_custkey = s.s_suppkey
JOIN 
    OrderSummaries os ON os.o_orderkey = o.o_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    LENGTH(s.s_comment) > 20
ORDER BY 
    os.total_extended_price DESC, name_length;
