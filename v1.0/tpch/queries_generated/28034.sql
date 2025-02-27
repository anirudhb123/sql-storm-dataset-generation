WITH SupplierParts AS (
    SELECT 
        s.s_name,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' in ', p.p_container, ' size of ', CAST(p.p_size AS VARCHAR), ' with a brand of ', p.p_brand) AS detailed_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        STRING_AGG(CONCAT('Order ', o.o_orderkey, ' on ', o.o_orderdate, ' with total of $', CAST(o.o_totalprice AS DECIMAL(12, 2))), '; ') AS order_details
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    sp.s_name,
    sp.p_name,
    sp.detailed_info,
    co.c_name,
    co.order_details
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON random() < 0.1 
ORDER BY 
    sp.s_name, co.c_name
LIMIT 100;
