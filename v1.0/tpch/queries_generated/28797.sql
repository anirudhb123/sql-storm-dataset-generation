WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_retailprice AS retail_price,
        ps.ps_availqty AS available_quantity,
        p.p_comment AS part_comment,
        CONCAT(s.s_name, ' supplies ', p.p_name) AS supplier_part_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_retailprice > 50.00
),
CustomerOrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        o.o_orderstatus AS order_status,
        o.o_orderdate AS order_date,
        o.o_totalprice AS total_price,
        CONCAT(c.c_name, ' placed order #', o.o_orderkey) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND o.o_totalprice < 1000.00
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    sp.retail_price,
    sp.available_quantity,
    sp.part_comment,
    co.customer_name,
    co.order_key,
    co.order_status,
    co.order_date,
    co.total_price,
    sp.supplier_part_info,
    co.customer_order_info
FROM 
    SupplierPartDetails sp
JOIN 
    CustomerOrderDetails co ON sp.available_quantity > 10
ORDER BY 
    sp.retail_price DESC, co.total_price ASC;
