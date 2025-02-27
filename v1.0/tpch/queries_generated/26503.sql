WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
supplier_summary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_supplycost) AS max_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_name
),
customer_order_summary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_name
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_retailprice, 
    ss.s_name AS supplier_name, 
    css.c_name AS customer_name, 
    css.total_orders, 
    css.total_spent
FROM 
    ranked_parts rp
JOIN 
    supplier_summary ss ON ss.total_parts > 10
JOIN 
    customer_order_summary css ON css.total_spent > 10000
WHERE 
    rp.price_rank <= 5
ORDER BY 
    rp.p_retailprice DESC, 
    ss.avg_supply_cost ASC, 
    css.total_orders DESC;
