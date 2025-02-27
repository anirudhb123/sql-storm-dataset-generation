WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_availqty > 0)
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS value_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
),
OrderLineInfo AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.p_partkey,
    r.p_name,
    h.o_orderkey,
    h.o_totalprice,
    oi.line_count,
    COALESCE(SUM(oi.net_revenue), 0) AS total_revenue,
    CASE 
        WHEN h.value_rank <= 5 THEN 'High Value'
        ELSE 'Standard Value'
    END AS order_value_category
FROM 
    RankedParts r
LEFT JOIN 
    HighValueOrders h ON r.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 1000.00)
LEFT JOIN 
    OrderLineInfo oi ON h.o_orderkey = oi.l_orderkey
WHERE 
    r.price_rank <= 10
GROUP BY 
    r.p_partkey, r.p_name, h.o_orderkey, h.o_totalprice, oi.line_count, h.value_rank
ORDER BY 
    total_revenue DESC, r.p_name;
