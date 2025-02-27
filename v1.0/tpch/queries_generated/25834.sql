WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names,
        STRING_AGG(DISTINCT CONCAT(n.n_name, ' (', r.r_name, ')'), '; ') AS nation_region
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
    GROUP BY 
        p.p_partkey
)
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
    a.supplier_names,
    a.customer_names,
    a.nation_region
FROM 
    part p 
JOIN 
    StringAggregation a ON p.p_partkey = a.p_partkey
WHERE 
    p.p_retailprice > 100.00
ORDER BY 
    p.p_size DESC, 
    a.supplier_names;
