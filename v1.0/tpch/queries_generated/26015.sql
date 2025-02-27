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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%Steel%'
),
SupplierAndNation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    san.nation_name,
    co.c_name,
    co.order_count,
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    SupplierAndNation san ON san.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = rp.p_partkey 
        ORDER BY ps.ps_supplycost DESC 
        LIMIT 1
    )
JOIN 
    CustomerOrders co ON co.total_spent > 1000
WHERE 
    rp.rank <= 10
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC;
