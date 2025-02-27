WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_brand, 
    rp.p_retailprice, 
    sd.s_name AS supplier_name, 
    sd.nation_name,
    os.total_revenue
FROM 
    RankedParts rp
LEFT JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_partkey = rp.p_partkey 
        ORDER BY o.o_orderdate DESC 
        LIMIT 1
    )
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC, sd.s_name;
