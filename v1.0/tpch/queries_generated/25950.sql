WITH part_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        STRING_AGG(DISTINCT CONCAT(c.c_name, '(', c.c_nationkey, ')'), '; ') AS customer_list
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
    WHERE 
        p.p_comment NOT LIKE '%out-of-stock%'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_comment, ps.ps_availqty, ps.ps_supplycost, s.s_name, o.o_orderkey
),
region_summary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        r.r_name
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_comment,
    pd.ps_availqty,
    pd.ps_supplycost,
    pd.supplier_name,
    rs.region_name,
    rs.nation_count,
    rs.total_available_qty,
    pd.customer_list
FROM 
    part_details pd
JOIN 
    region_summary rs ON pd.ps_availqty > rs.total_available_qty
ORDER BY 
    pd.p_partkey, rs.region_name DESC;
