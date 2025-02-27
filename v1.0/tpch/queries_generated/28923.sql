WITH StringAggregation AS (
    SELECT 
        p.p_name,
        s.s_name,
        CONCAT(p.p_name, ' from supplier ', s.s_name) AS full_description,
        CONCAT('Retail Price: ', CAST(p.p_retailprice AS VARCHAR), ', Comment: ', p.p_comment) AS details,
        STRING_AGG(CONCAT('Order:', CAST(o.o_orderkey AS VARCHAR), ' - Status: ', o.o_orderstatus), '; ') AS order_info
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        p.p_retailprice > 0 AND 
        s.s_acctbal > 0
    GROUP BY 
        p.p_name, s.s_name, p.p_retailprice, p.p_comment
)
SELECT 
    full_description, 
    details, 
    order_info
FROM 
    StringAggregation
ORDER BY 
    p_name, s_name;
