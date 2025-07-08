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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00
),
suppliers_with_comments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        REPLACE(s.s_comment, 'bad', 'good') AS modified_comment
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
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        MAX(l.l_shipdate) AS latest_shipdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)

SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    swc.s_name,
    swc.modified_comment,
    od.total_price,
    od.part_count,
    od.latest_shipdate
FROM 
    ranked_parts rp
JOIN 
    suppliers_with_comments swc ON swc.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = rp.p_partkey
        ORDER BY ps.ps_supplycost DESC
        LIMIT 1
    )
JOIN 
    order_details od ON od.o_orderkey = (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_custkey = swc.s_suppkey
        ORDER BY o.o_orderdate DESC
        LIMIT 1
    )
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, od.total_price ASC;