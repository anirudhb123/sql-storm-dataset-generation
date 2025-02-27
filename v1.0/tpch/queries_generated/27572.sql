WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal
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
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    si.s_name AS supplier_name,
    si.nation_name,
    co.c_name AS customer_name,
    co.order_count
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierInfo si ON ps.ps_suppkey = si.s_suppkey
JOIN 
    CustomerOrders co ON si.s_suppkey IN (
        SELECT 
            l.l_suppkey 
        FROM 
            lineitem l
        JOIN 
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE 
            o.o_orderstatus = 'F'
    )
WHERE 
    rp.brand_rank <= 5
ORDER BY 
    rp.p_retailprice DESC, 
    co.order_count DESC, 
    si.nation_name;
