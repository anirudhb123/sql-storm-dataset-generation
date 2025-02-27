WITH supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        REPLACE(s.s_address, 'Street', 'St.') AS formatted_address,
        s.s_phone,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey, s.s_address, s.s_phone
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        SUBSTRING(c.c_name, 1, 10) AS short_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
nation_region AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sd.s_name,
    sd.formatted_address,
    nr.region_name,
    cs.short_name,
    cs.order_count,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent > 10000 THEN 'Premium'
        ELSE 'Regular'
    END AS customer_tier
FROM 
    supplier_details sd
JOIN 
    nation_region nr ON sd.s_nationkey = nr.n_nationkey
LEFT JOIN 
    customer_summary cs ON cs.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_nationkey = sd.s_nationkey)
WHERE 
    sd.avg_supplycost > 200
ORDER BY 
    sd.s_name, cs.total_spent DESC;
