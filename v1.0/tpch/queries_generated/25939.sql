WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_retailprice, 
    co.c_name AS customer_name, 
    co.total_spent,
    sd.nation_name,
    sd.parts_supplied
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON co.order_count > 5
JOIN 
    SupplierDetails sd ON sd.parts_supplied > 10
WHERE 
    rp.rank <= 3
ORDER BY 
    rp.p_retailprice DESC, co.total_spent DESC;
