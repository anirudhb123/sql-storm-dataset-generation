
WITH string_aggregates AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        STRING_AGG(DISTINCT c.c_name, ', ') AS customers,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_revenue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size
)
SELECT 
    p.p_partkey AS partkey, 
    p.p_name AS part_name, 
    p.p_mfgr, 
    p.p_brand, 
    p.p_type, 
    p.p_size, 
    sa.suppliers, 
    sa.customers, 
    sa.order_count, 
    sa.total_quantity, 
    sa.lineitem_count, 
    sa.total_revenue
FROM 
    string_aggregates sa
JOIN 
    part p ON sa.p_partkey = p.p_partkey
WHERE 
    sa.order_count > 10 
ORDER BY 
    sa.total_revenue DESC 
LIMIT 20;
