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
        p.p_retailprice > 100.00
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000.00
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
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address
)
SELECT 
    rp.p_name AS top_part,
    rp.p_retailprice AS top_price,
    sd.s_name AS supplier_name,
    sd.nation_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerOrders co ON EXISTS (
        SELECT 1 
        FROM lineitem li 
        WHERE li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey) 
        AND li.l_partkey = rp.p_partkey
    )
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, sd.s_name, co.total_spent DESC;
