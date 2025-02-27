WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name, 
        s.s_acctbal, 
        CONCAT(s.s_name, ' from ', n.n_name) AS supplier_info
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        LEFT(p.p_comment, 15) AS short_comment
    FROM 
        part p 
    WHERE 
        p.p_retailprice > 100.00
),
AggregatedOrderData AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.supplier_info, 
    pd.p_name, 
    pd.p_brand, 
    pd.p_retailprice, 
    aod.total_price
FROM 
    SupplierDetails sd
JOIN 
    Partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    AggregatedOrderData aod ON ps.ps_supplycost < aod.total_price
WHERE 
    sd.s_acctbal > 5000
ORDER BY 
    aod.total_price DESC, 
    sd.supplier_info;
