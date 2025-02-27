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
        LENGTH(p.p_name) > 10
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name as nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 1000
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_mktsegment
    FROM 
        customer c
    WHERE 
        c.c_name LIKE '%Corp%'
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.total_price,
    o.item_count
FROM 
    RankedParts r
JOIN 
    SupplierInfo s ON r.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN 
    CustomerDetails c ON c.c_custkey IN (SELECT o.o_custkey FROM OrderSummary o WHERE o.item_count > 1)
JOIN 
    OrderSummary o ON o.o_custkey = c.c_custkey
WHERE 
    r.rank <= 5
ORDER BY 
    r.p_brand, total_price DESC;
