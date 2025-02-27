
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        DENSE_RANK() OVER (PARTITION BY p.p_container ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    ss.s_name,
    rp.p_name,
    os.total_order_value,
    os.item_count,
    CASE 
        WHEN os.total_order_value > 1000 THEN 'High Value'
        WHEN os.total_order_value BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    RankedParts rp ON ss.unique_parts = 
    (SELECT 
        MAX(rp2.price_rank) 
     FROM 
        RankedParts rp2 
     WHERE 
        rp2.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey))
LEFT JOIN 
    OrderSummary os ON os.item_count = ss.unique_parts
WHERE 
    COALESCE(ss.total_available, 0) > 100
ORDER BY 
    r.r_name, ss.avg_acctbal DESC, os.total_order_value ASC;
