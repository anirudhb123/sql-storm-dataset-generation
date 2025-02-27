WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 100)
),
CustomerRecentOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS recent_order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey AND o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 0
            ELSE s.s_acctbal
        END AS adjusted_balance
    FROM 
        supplier s
)
SELECT 
    r.r_name,
    p.p_name,
    COALESCE(p.p_retailprice, 0) AS retail_price,
    d.s_name,
    d.adjusted_balance,
    c.c_name,
    COALESCE(crc.recent_order_count, 0) AS recent_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_quantity) AS max_quantity,
    AVG(CASE WHEN l.l_discount IS NULL THEN 0 ELSE l.l_discount END) AS avg_discount_rate
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedParts p ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerRecentOrders crc ON crc.c_custkey = (SELECT TOP 1 c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey ORDER BY c.c_acctbal DESC)
GROUP BY 
    r.r_name, p.p_name, d.s_name, d.adjusted_balance, c.c_name, crc.recent_order_count
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 10
ORDER BY 
    total_revenue DESC;
