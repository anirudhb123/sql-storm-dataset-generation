WITH StringAggregation AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' - ', p.p_mfgr, ' ', p.p_brand) AS combined_info,
        COUNT(DISTINCT s.s_name) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        STRING_AGG(DISTINCT s.s_comment, '; ') AS supplier_comments
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT o.o_orderpriority, ', ') AS order_priorities
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sa.combined_info,
    sa.supplier_count,
    sa.total_available_quantity,
    sa.supplier_comments,
    cod.c_name,
    cod.total_orders,
    cod.total_spent,
    cod.order_priorities
FROM 
    StringAggregation sa
JOIN 
    CustomerOrderDetails cod ON sa.supplier_count > 5
ORDER BY 
    sa.total_available_quantity DESC, cod.total_spent DESC;
