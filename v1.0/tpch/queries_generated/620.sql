WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        c.c_custkey
),
LineItemAnalysis AS (
    SELECT 
        l.l_partkey,
        COUNT(*) AS total_lines,
        AVG(l.l_extendedprice) AS avg_price,
        SUM(l.l_discount) AS total_discount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(os.total_order_value, 0) AS total_order_value,
    COALESCE(la.total_lines, 0) AS total_lines,
    la.avg_price,
    la.total_discount
FROM 
    part p
LEFT JOIN 
    SupplierStats ss ON p.p_partkey = ANY (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
LEFT JOIN 
    OrderSummary os ON os.c_custkey IN (SELECT c.c_custkey FROM customer c JOIN orders o ON c.c_custkey = o.o_custkey WHERE o.o_orderstatus = 'O' OR o.o_orderstatus = 'F')
LEFT JOIN 
    LineItemAnalysis la ON p.p_partkey = la.l_partkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_type = p.p_type)
ORDER BY 
    total_supply_cost DESC, total_order_value DESC, total_lines DESC;
