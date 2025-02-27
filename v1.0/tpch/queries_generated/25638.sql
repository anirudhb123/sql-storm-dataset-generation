WITH StringPatterns AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        l.l_quantity,
        o.o_orderdate,
        o.o_orderpriority,
        STRING_AGG(DISTINCT r.r_name, ', ') AS regions,
        MATLAB_BW(p.p_comment) AS comment_match_weight
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        p.p_name LIKE '%part%'
        AND s.s_name NOT LIKE '%supplier%'
        AND c.c_acctbal > 1000
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_container, 
        p.p_retailprice, p.p_comment, s.s_name, c.c_name, l.l_quantity, 
        o.o_orderdate, o.o_orderpriority
)
SELECT 
    p_partkey,
    p_name,
    p_mfgr,
    p_brand,
    p_type,
    p_container,
    p_retailprice,
    p_comment,
    supplier_name,
    customer_name,
    SUM(l_quantity) AS total_quantity,
    AVG(comment_match_weight) AS average_comment_weight,
    COUNT(DISTINCT o_orderdate) AS unique_order_dates,
    STRING_AGG(DISTINCT regions, '; ') AS unique_regions
FROM 
    StringPatterns
GROUP BY 
    p_partkey, p_name, p_mfgr, p_brand, p_type, p_container, 
    p_retailprice, p_comment, supplier_name, customer_name
ORDER BY 
    total_quantity DESC, average_comment_weight DESC;
