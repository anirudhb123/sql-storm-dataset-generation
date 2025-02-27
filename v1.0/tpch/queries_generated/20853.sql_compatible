
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' 
        AND o.o_orderdate < '1997-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(NULLIF(s.s_address, ''), 'Unknown') AS s_address,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate,
        r.o_totalprice,
        SUM(CASE WHEN l.l_discount > 0.1 THEN 1 ELSE 0 END) AS high_discount_lines
    FROM 
        RankedOrders r
    JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    WHERE 
        r.rnk <= 5
    GROUP BY 
        r.o_orderkey, r.o_orderdate, r.o_totalprice
),
FilteredSuppliers AS (
    SELECT 
        sd.s_suppkey, 
        sd.s_name, 
        sd.s_address 
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierDetails)
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.o_totalprice,
    COALESCE(h.high_discount_lines, 0) AS high_discount_count,
    s.s_name,
    s.s_address
FROM 
    HighValueOrders h
FULL OUTER JOIN 
    lineitem l ON h.o_orderkey = l.l_orderkey
LEFT JOIN 
    FilteredSuppliers s ON l.l_suppkey = s.s_suppkey
WHERE 
    (h.o_orderdate IS NOT NULL AND h.o_orderdate = '1997-06-15') OR 
    (s.s_address IS NOT NULL AND s.s_address LIKE '%Street%')
ORDER BY 
    h.o_totalprice DESC 
LIMIT 100
OFFSET (SELECT COUNT(*) FROM orders) % 50;
