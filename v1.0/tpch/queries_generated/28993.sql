WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%delivered%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_comment LIKE '%reliable%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    COALESCE(sd.nation_name, 'Unknown') AS supplier_nation,
    COALESCE(cd.total_spent, 0) AS total_customer_spent,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rp.p_retailprice) OVER () AS median_retail_price
FROM 
    RankedParts r
LEFT JOIN 
    SupplierDetails sd ON r.p_brand = sd.s_name
LEFT JOIN 
    CustomerOrders cd ON r.p_partkey = cd.o_orderkey
WHERE 
    r.rn <= 10
ORDER BY 
    r.p_retailprice DESC, r.p_name;
