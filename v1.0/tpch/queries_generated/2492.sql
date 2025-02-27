WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate > '2023-01-01' 
        AND o.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        SUM(ps.ps_availqty) AS total_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100.00
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        SUM(ps.ps_availqty) > 50
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(hp.p_name, 'Unknown Part') AS part_name,
    ss.s_name AS supplier_name,
    ss.total_available,
    hp.total_quantity
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighValueParts hp ON l.l_partkey = hp.p_partkey
LEFT JOIN 
    SupplierStats ss ON l.l_suppkey = ss.s_suppkey
WHERE 
    r.rn <= 10 
    AND (ss.total_available IS NULL OR ss.total_available > 20)
ORDER BY 
    r.o_orderdate DESC, 
    r.o_totalprice DESC;
