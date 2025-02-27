
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
        POSITION('eco' IN p.p_comment) > 0
),
SupplierDetails AS (
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
        s.s_acctbal > 5000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sale,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_brand,
    s.s_name,
    s.nation_name,
    os.total_sale,
    os.order_count
FROM 
    RankedParts p
JOIN 
    SupplierDetails s ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey LIMIT 1)
JOIN 
    OrderSummary os ON os.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey LIMIT 1)
WHERE 
    p.rank <= 5
ORDER BY 
    p.p_brand, os.total_sale DESC;
