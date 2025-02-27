
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
        p.p_retailprice IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_count,
        MAX(l.l_shipmode) AS max_ship_mode
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND o.o_totalprice > 1000
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    ss.total_supply_cost,
    hvo.total_price,
    hvo.line_count,
    hvo.max_ship_mode,
    CASE 
        WHEN ss.total_supply_cost IS NULL THEN 'No Suppliers'
        ELSE 'Supplier Exists'
    END AS supplier_status,
    COALESCE(NULLIF(hvo.total_price, 0), (SELECT AVG(total_supply_cost) FROM SupplierStats)) AS avg_price_fallback
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierStats ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
LEFT JOIN 
    HighValueOrders hvo ON hvo.total_price > (SELECT AVG(total_price) FROM HighValueOrders) 
WHERE 
    rp.rn = 1 
ORDER BY 
    rp.p_retailprice DESC
LIMIT 10;
