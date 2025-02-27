WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank_price,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment
    FROM 
        part p
    WHERE 
        p.p_size > 10
),
top_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 5
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    tp.s_name AS top_supplier,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    rp.short_comment
FROM 
    ranked_parts rp
JOIN 
    top_suppliers tp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = tp.s_suppkey)
JOIN 
    customer_orders co ON co.order_count > 3
WHERE 
    rp.rank_price <= 5
ORDER BY 
    rp.p_retailprice DESC, co.total_spent DESC;
