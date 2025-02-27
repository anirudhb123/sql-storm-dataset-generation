
WITH CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_address, c.c_phone
),
ProductSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
OrderLineItem AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        p.p_name AS product_name
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
)
SELECT 
    co.c_name,
    co.c_address,
    co.c_phone,
    SUM(ol.l_extendedprice * (1 - ol.l_discount)) AS revenue,
    COUNT(DISTINCT ol.l_orderkey) AS total_orders,
    AVG(co.total_spent) AS avg_spent,
    p.supplier_name,
    STRING_AGG(DISTINCT p.p_name, ', ') AS products_supplied
FROM 
    CustomerOrderDetails co
JOIN 
    OrderLineItem ol ON co.c_custkey = ol.l_orderkey
JOIN 
    ProductSuppliers p ON ol.l_partkey = p.p_partkey
GROUP BY 
    co.c_name, co.c_address, co.c_phone, p.supplier_name
ORDER BY 
    revenue DESC, total_orders DESC;
