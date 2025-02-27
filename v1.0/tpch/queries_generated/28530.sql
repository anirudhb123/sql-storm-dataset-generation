WITH PartAnalysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_comment) AS comment_length,
        CASE 
            WHEN p.p_type LIKE '%plastic%' THEN 'Plastic'
            WHEN p.p_type LIKE '%metal%' THEN 'Metal'
            WHEN p.p_type LIKE '%wood%' THEN 'Wood'
            ELSE 'Other'
        END AS material_type,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_comment, p.p_type
),
SupplierAnalysis AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUBSTRING(s.s_comment FROM 1 FOR 30) AS short_comment,
        COUNT(ps.ps_partkey) AS num_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_comment
),
OrderAnalysis AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_ordered
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    pa.p_partkey,
    pa.p_name,
    pa.comment_length,
    pa.material_type,
    pa.total_supply_cost,
    sa.s_suppkey,
    sa.s_name,
    sa.short_comment,
    sa.num_parts_supplied,
    oa.o_orderkey,
    oa.total_order_value,
    oa.distinct_parts_ordered
FROM 
    PartAnalysis pa
JOIN 
    SupplierAnalysis sa ON pa.total_supply_cost > 50000
JOIN 
    OrderAnalysis oa ON oa.total_order_value > 1000
ORDER BY 
    pa.p_partkey, sa.s_suppkey, oa.o_orderkey;
