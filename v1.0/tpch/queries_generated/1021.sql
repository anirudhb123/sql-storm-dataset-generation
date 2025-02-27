WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(SUM(sp.total_available_qty), 0) AS total_available_qty,
    COALESCE(LOS.line_count, 0) AS order_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
    ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC, p.p_partkey) AS rank
FROM 
    part p
LEFT JOIN 
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN 
    LineItemStats LOS ON LOS.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM RankedOrders
        WHERE rn <= 10
    )
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_retailprice > 50.00 
    AND (p.p_comment IS NULL OR p.p_comment LIKE '%high-quality%')
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand
ORDER BY 
    total_available_qty DESC, rank;
