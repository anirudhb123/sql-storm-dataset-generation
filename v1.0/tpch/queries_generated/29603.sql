WITH part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        SUBSTRING(p.p_comment FROM 1 FOR 23) AS short_comment,
        LENGTH(REPLACE(p.p_comment, ' ', '')) AS non_space_length
    FROM 
        part p
), 
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        LENGTH(s.s_comment) AS comment_length,
        LEFT(s.s_comment, 50) AS short_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
order_and_item AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
) 
SELECT 
    ps.p_partkey,
    ps.short_comment AS part_comment,
    ss.s_name AS supplier_name,
    ss.nation_name,
    oai.total_quantity AS total_ordered,
    oai.distinct_parts,
    ps.non_space_length AS part_comment_length,
    ss.comment_length AS supplier_comment_length
FROM 
    part_summary ps
JOIN 
    partsupp psu ON ps.p_partkey = psu.ps_partkey
JOIN 
    supplier_summary ss ON psu.ps_suppkey = ss.s_suppkey
JOIN 
    order_and_item oai ON psu.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = oai.o_orderkey
    )
WHERE 
    ps.p_retailprice > 100.00
ORDER BY 
    total_quantity DESC, 
    part_comment_length DESC;
