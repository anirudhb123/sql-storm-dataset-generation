WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%urgent%'
),
filtered_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000.00
),
order_details AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    fp.s_name AS supplier_name,
    fp.supplier_nation,
    rp.p_name AS part_name,
    rp.p_brand,
    fd.total_revenue,
    fd.distinct_parts
FROM 
    filtered_suppliers fp
JOIN 
    ranked_parts rp ON rp.price_rank <= 5
JOIN 
    order_details fd ON fd.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        JOIN 
            partsupp ps ON l.l_partkey = ps.ps_partkey
        WHERE 
            ps.ps_suppkey = fp.s_suppkey
    )
WHERE 
    (fp.s_name LIKE '%Corp%' OR fp.s_name LIKE '%Inc%')
ORDER BY 
    fp.s_name, rp.p_retailprice DESC;
