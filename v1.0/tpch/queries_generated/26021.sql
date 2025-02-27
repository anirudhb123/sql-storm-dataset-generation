WITH ranked_parts AS (
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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand, p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
filtered_parts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        rp.p_brand,
        rp.p_type,
        rp.p_size,
        rp.p_container,
        rp.p_retailprice,
        rp.p_comment
    FROM 
        ranked_parts rp
    WHERE 
        rp.rank <= 5
),
nation_supplier AS (
    SELECT 
        n.n_name,
        s.s_name,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
)
SELECT 
    fp.p_name,
    fp.p_brand,
    fp.p_type,
    ns.n_name,
    ns.s_name,
    ns.s_acctbal,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    filtered_parts fp
JOIN 
    lineitem l ON l.l_partkey = fp.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    nation_supplier ns ON ns.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = ns.s_name))
GROUP BY 
    fp.p_name, fp.p_brand, fp.p_type, ns.n_name, ns.s_name, ns.s_acctbal
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
