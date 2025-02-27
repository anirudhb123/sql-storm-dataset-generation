WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), OrdersSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        COUNT(l.l_orderkey) AS total_line_items, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    rp.p_brand, 
    ss.s_name AS supplier_name,
    os.total_order_value,
    (rp.total_cost / NULLIF(os.total_order_value, 0)) * 100 AS cost_percentage_of_order
FROM 
    RankedParts rp
JOIN 
    SupplierStats ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
JOIN 
    OrdersSummary os ON os.total_line_items > 0
WHERE 
    rp.total_cost > 1000
ORDER BY 
    cost_percentage_of_order DESC
LIMIT 10;
