WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
),
CustomerNation AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, n.n_name
),
SupplierCommentAggregate AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        STRING_AGG(s.s_comment, ' | ') AS combined_comments
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    cn.nation_name,
    cn.total_orders,
    sca.combined_comments
FROM 
    RankedParts rp
JOIN 
    CustomerNation cn ON cn.total_orders > 5
JOIN 
    SupplierCommentAggregate sca ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sca.s_suppkey)
WHERE 
    rp.rank <= 3
ORDER BY 
    rp.p_retailprice DESC, cn.total_orders DESC;
