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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
),
HighPriceParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        rp.p_comment,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        rp.rn <= 5  -- Top 5 most expensive parts per type
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 2
)
SELECT 
    hpp.p_name,
    hpp.p_retailprice,
    hpp.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.total_spent,
    hpp.p_comment
FROM 
    HighPriceParts hpp
JOIN 
    CustomerOrders co ON co.total_spent > 10000  -- Only customers who spent more than 10,000
ORDER BY 
    hpp.p_retailprice DESC, co.total_spent DESC;
