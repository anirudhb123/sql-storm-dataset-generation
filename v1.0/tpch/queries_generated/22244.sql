WITH RECURSIVE price_analysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 0
            ELSE p.p_retailprice 
        END AS adjusted_price,
        1 AS recursion_level
    FROM 
        part p
    UNION ALL
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN pa.adjusted_price IS NOT NULL AND pa.adjusted_price > 100 THEN pa.adjusted_price * 0.9
            ELSE pa.adjusted_price * 1.05
        END,
        pa.recursion_level + 1
    FROM 
        price_analysis pa
    JOIN 
        part p ON pa.recursion_level < 3
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(CASE 
            WHEN o.o_orderstatus = 'O' THEN o.o_totalprice 
            ELSE 0 
        END) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    c.c_name,
    COALESCE(SUM(pa.adjusted_price), 0) AS avg_price_adjusted,
    COALESCE(s.total_supply_cost, 0) AS supplier_cost,
    CASE 
        WHEN COALESCE(c.total_spent, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(c.total_spent, 0) = 0 THEN 'No Orders'
        ELSE 'Regular'
    END AS customer_value_segment
FROM 
    customer_orders c
LEFT JOIN 
    price_analysis pa ON c.order_count > 0
LEFT JOIN 
    supplier_summary s ON s.part_count > 0
WHERE 
    c.order_count >= (SELECT AVG(order_count) FROM customer_orders)
GROUP BY 
    c.c_name, s.total_supply_cost
HAVING 
    COUNT(DISTINCT c.c_custkey) > 1
ORDER BY 
    customer_value_segment DESC, avg_price_adjusted DESC;
