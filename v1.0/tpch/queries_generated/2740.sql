WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_price
    FROM 
        part p
),
supplier_part_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
high_value_suppliers AS (
    SELECT 
        sps.s_suppkey,
        sps.s_name
    FROM 
        supplier_part_summary sps
    WHERE 
        sps.total_supply_cost > 50000
),
customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
recent_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name
    FROM 
        orders o
    INNER JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    r.p_retailprice,
    ch.c_name AS customer_name,
    ch.order_count,
    ch.total_spent,
    COALESCE(sv.s_name, 'No Supplier') AS supplier_name,
    (CASE 
        WHEN r.rank_price <= 10 THEN 'High Value'
        ELSE 'Standard'
    END) AS part_value_category
FROM 
    ranked_parts r
LEFT JOIN 
    customer_order_summary ch ON ch.order_count > 5
LEFT JOIN 
    high_value_suppliers sv ON sv.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = r.p_partkey)
WHERE 
    r.p_retailprice >= 100
ORDER BY 
    r.p_retailprice DESC, ch.total_spent DESC;
