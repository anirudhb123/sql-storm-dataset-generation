WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%widget%'
),
SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        rp.p_comment
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        rp.brand_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-10-01'
    GROUP BY 
        c.c_name, o.o_orderkey
)
SELECT 
    sp.supplier_name,
    sp.p_name,
    sp.p_retailprice,
    co.customer_name,
    co.total_spent,
    co.order_count
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = sp.supplier_name))
ORDER BY 
    sp.supplier_name, co.total_spent DESC;