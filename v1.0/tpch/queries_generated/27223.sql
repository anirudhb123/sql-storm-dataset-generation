WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        REGEXP_COUNT(s.s_comment, '[A-Za-z]+') AS word_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        n.n_name AS nation_name,
        c.c_acctbal,
        LENGTH(c.c_comment) AS comment_length,
        REGEXP_COUNT(c.c_comment, '[A-Za-z]+') AS word_count
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        LENGTH(p.p_comment) AS comment_length,
        REGEXP_COUNT(p.p_comment, '[A-Za-z]+') AS word_count
    FROM 
        part p
)
SELECT 
    s.s_name AS supplier_name,
    s.nation_name AS supplier_nation,
    s.comment_length AS supplier_comment_length,
    s.word_count AS supplier_word_count,
    c.c_name AS customer_name,
    c.nation_name AS customer_nation,
    c.comment_length AS customer_comment_length,
    c.word_count AS customer_word_count,
    p.p_name AS part_name,
    p.p_brand AS part_brand,
    p.comment_length AS part_comment_length,
    p.word_count AS part_word_count
FROM 
    SupplierDetails s
JOIN 
    CustomerDetails c ON s.s_suppkey % c.c_custkey = 0
JOIN 
    PartDetails p ON p.p_partkey = s.s_suppkey % 100
WHERE 
    s.s_acctbal > 10000 AND 
    c.c_acctbal < 5000 AND 
    p.p_size BETWEEN 1 AND 50
ORDER BY 
    s.s_name, c.c_name, p.p_name;
