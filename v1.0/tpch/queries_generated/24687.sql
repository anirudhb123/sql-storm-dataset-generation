WITH RECURSIVE customer_orders AS (
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
), prices AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), high_value_suppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
), combined_data AS (
    SELECT 
        co.c_name, 
        co.order_count,
        co.total_spent,
        hs.total_value,
        p.p_size,
        CASE 
            WHEN co.total_spent IS NULL THEN 'No Order'
            WHEN co.total_spent > 5000 THEN 'High Roller'
            ELSE 'Regular'
        END AS customer_category
    FROM 
        customer_orders co
    FULL OUTER JOIN 
        high_value_suppliers hs ON co.c_custkey = hs.s_suppkey
    LEFT JOIN 
        prices p ON hs.s_suppkey = p.p_partkey AND p.price_rank = 1
)
SELECT 
    c_name,
    order_count,
    total_spent,
    total_value,
    p_size,
    customer_category
FROM 
    combined_data
WHERE 
    (customer_category = 'High Roller' OR customer_category = 'Regular')
    AND (total_value IS NOT NULL OR p_size IS NOT NULL)
ORDER BY 
    total_spent DESC NULLS LAST, 
    p_size NULLS FIRST
LIMIT 100;
