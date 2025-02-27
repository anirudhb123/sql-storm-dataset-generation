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
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        COUNT(ps.ps_supplycost) as total_supplies
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        LENGTH(s.s_comment) > 10 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone, s.s_acctbal
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) as total_spent,
        COUNT(o.o_orderkey) as total_orders,
        STRING_AGG(DISTINCT p.p_name, ', ') AS purchased_parts
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_retailprice,
    s.s_name,
    s.total_supplies,
    c.c_name,
    c.total_spent,
    c.total_orders,
    c.purchased_parts
FROM 
    RankedParts r
JOIN 
    SupplierDetails s ON r.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN 
    CustomerPurchases c ON c.purchased_parts LIKE '%' || r.p_name || '%'
WHERE 
    r.rank <= 5 
ORDER BY 
    r.p_retailprice DESC, s.total_supplies DESC, c.total_spent DESC;
