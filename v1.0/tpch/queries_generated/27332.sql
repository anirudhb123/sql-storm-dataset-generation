WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        LENGTH(p.p_name) AS name_length,
        UPPER(SUBSTRING(p.p_comment FROM 1 FOR 10)) AS preview_comment,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_by_price
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 1000)
), supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COUNT(ps.ps_supplycost) AS parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 500
    GROUP BY 
        c.c_custkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.preview_comment,
    si.s_name,
    si.parts_supplied,
    co.total_orders,
    co.total_spent,
    co.last_order_date
FROM 
    ranked_parts rp
JOIN 
    supplier_info si ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost > 200)
JOIN 
    customer_orders co ON co.total_spent > 10000
WHERE 
    rp.rank_by_price <= 3
ORDER BY 
    rp.name_length DESC, co.total_spent DESC;
