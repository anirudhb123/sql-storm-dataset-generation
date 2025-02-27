WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' provides ', p.p_name, ' with available quantity ', ps.ps_availqty, ' at a cost of ', FORMAT(ps.ps_supplycost, 2)) AS supplier_part_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10 AND 
        s.s_acctbal > 1000
),
CustomerOrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        o.o_totalprice AS total_price,
        o.o_orderdate AS order_date,
        CONCAT(c.c_name, ' placed an order with total price ', FORMAT(o.o_totalprice, 2), ' on ', DATE_FORMAT(o.o_orderdate, '%Y-%m-%d')) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_totalprice > 100
)
SELECT
    SPD.supplier_part_info,
    COD.customer_order_info
FROM 
    SupplierPartDetails SPD
JOIN 
    CustomerOrderDetails COD ON SPD.available_quantity > 50
ORDER BY 
    SPD.supplier_name, 
    COD.order_date DESC;
