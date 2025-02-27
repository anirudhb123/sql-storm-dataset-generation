WITH PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        MAX(p.p_retailprice) AS max_price,
        MIN(p.p_retailprice) AS min_price,
        AVG(p.p_retailprice) AS avg_price,
        STRING_AGG(p.p_comment, '; ') AS aggregated_comments
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container
),
CustomerFeedback AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        STRING_AGG(o.o_comment, '; ') AS order_comments
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.supplier_count,
    ps.total_avail_qty,
    ps.max_price,
    ps.min_price,
    ps.avg_price,
    ps.aggregated_comments,
    cf.c_custkey,
    cf.c_name,
    cf.order_comments
FROM 
    PartStats ps
LEFT JOIN 
    CustomerFeedback cf ON ps.supplier_count > 1
ORDER BY 
    ps.supplier_count DESC, ps.avg_price DESC;
