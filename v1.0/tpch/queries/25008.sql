WITH OrderedData AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        s.s_name AS supplier_name,
        p.p_name,
        l.l_quantity,
        l.l_extendedprice,
        l.l_shipdate,
        l.l_returnflag,
        l.l_linestatus,
        CONCAT(LEFT(c.c_address, 20), '...', RIGHT(c.c_address, 15)) AS short_address,
        CONCAT('Order: ', o.o_orderkey, ' | ', s.s_name) AS order_info,
        CASE 
            WHEN l.l_discount > 0.1 THEN 'High Discount'
            ELSE 'Regular Discount'
        END AS discount_category
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON l.l_partkey = p.p_partkey
)
SELECT 
    COUNT(*) AS total_orders,
    AVG(l_extendedprice) AS average_price,
    SUM(CASE WHEN l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns,
    MAX(l_shipdate) AS latest_shipping,
    discount_category,
    STRING_AGG(DISTINCT short_address, '; ') AS unique_addresses
FROM 
    OrderedData
GROUP BY 
    discount_category
ORDER BY 
    total_orders DESC;
