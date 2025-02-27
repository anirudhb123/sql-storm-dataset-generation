WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            WHEN p.p_size < 10 THEN 'Small'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
            ELSE 'Large'
        END AS size_category
    FROM 
        part p
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
        LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.size_category,
    sd.s_name AS supplier_name,
    COALESCE(cd.total_spent, 0) AS customer_spent,
    ld.net_revenue AS lineitem_revenue
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierDetails sd ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sd.s_suppkey)
LEFT JOIN 
    CustomerOrders cd ON cd.order_count > 0
LEFT JOIN 
    LineItemDetails ld ON ld.l_orderkey = ANY(SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cd.c_custkey)
WHERE 
    rp.price_rank = 1
    AND (sd.part_count > 0 OR sd.part_count IS NULL)
ORDER BY 
    rp.p_partkey DESC, cd.total_spent ASC NULLS LAST;
