WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SMALLINT '5', SMALLINT '10', SMALLINT '15')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
CombinedData AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.p_retailprice,
        sd.s_name AS supplier_name,
        sd.supplier_nation
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    WHERE 
        rp.price_rank <= 3
)
SELECT 
    c.c_custkey,
    c.c_name,
    cd.p_name,
    cd.p_retailprice,
    cd.supplier_name,
    cd.supplier_nation
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    CombinedData cd ON l.l_partkey = cd.p_partkey
WHERE 
    o.o_orderstatus = 'O'
ORDER BY 
    c.c_name, cd.p_retailprice DESC;
