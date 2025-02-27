WITH StringAgg AS (
    SELECT 
        p.p_name,
        CONCAT(LEFT(p.p_name, 5), '...', RIGHT(p.p_name, 5)) AS short_name,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderdate,
        o.o_totalprice,
        LISTAGG(DISTINCT CONCAT('Item: ', p.p_name, ' (', p.p_brand, ')'), '; ') WITHIN GROUP (ORDER BY p.p_partkey) AS all_items,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
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
        p.p_name, s.s_name, c.c_name, o.o_orderdate, o.o_totalprice
)
SELECT 
    short_name,
    supplier_name,
    SUM(o_totalprice) AS total_revenue,
    STRING_AGG(customer_name, ', ') AS customers,
    COUNT(total_orders) AS order_count
FROM 
    StringAgg
GROUP BY 
    short_name, supplier_name
HAVING 
    total_revenue > 10000
ORDER BY 
    total_revenue DESC;
