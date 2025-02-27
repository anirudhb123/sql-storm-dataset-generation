
WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LOWER(SUBSTRING(p.p_comment, 1, 15)) AS short_comment,
        CHAR_LENGTH(p.p_container) AS container_length,
        REGEXP_REPLACE(p.p_brand, '[^a-zA-Z]', '') AS clean_brand
    FROM 
        part p
), 
popular_suppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_quantity
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 100
), 
customer_orders AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spending
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name
)
SELECT 
    pp.upper_name,
    pp.short_comment,
    ps.total_quantity,
    co.order_count,
    co.total_spending
FROM 
    processed_parts pp
JOIN 
    popular_suppliers ps ON pp.p_partkey = ps.ps_partkey
JOIN 
    customer_orders co ON pp.p_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = co.c_custkey LIMIT 1)
WHERE 
    pp.container_length > 5
ORDER BY 
    co.total_spending DESC
FETCH FIRST 100 ROWS ONLY;
