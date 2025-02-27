WITH RankedParts AS (
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
        CHARINDEX('deluxe', p.p_comment) > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_parts
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        RankedParts rp ON l.l_partkey = rp.p_partkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    co.order_count,
    co.total_spent,
    rp.p_brand,
    RPAD(rp.p_comment, 100, ' ') AS padded_comment
FROM 
    CustomerOrders co
JOIN 
    RankedParts rp ON co.total_spent > 1000 AND CHARINDEX('special', rp.p_comment) > 0
ORDER BY 
    co.total_spent DESC, co.c_name;
