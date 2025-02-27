WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        s.s_comment AS supplier_comment,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with quantity ', ps.ps_availqty, ' at a cost of ', ps.ps_supplycost) AS detailed_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey AS order_id,
        c.c_name AS customer_name,
        o.o_orderdate AS order_date,
        o.o_totalprice AS total_price,
        o.o_comment AS order_comment,
        CONCAT('Order ', o.o_orderkey, ' by ', c.c_name, ' on ', o.o_orderdate, ' for total price of ', o.o_totalprice) AS order_info
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    spd.supplier_name,
    spd.part_name,
    spd.available_quantity,
    spd.supply_cost,
    spd.supplier_comment,
    spd.detailed_info,
    od.order_id,
    od.customer_name,
    od.order_date,
    od.total_price,
    od.order_comment,
    od.order_info
FROM 
    SupplierPartDetails spd
LEFT JOIN 
    OrderDetails od ON spd.supplier_name LIKE '%' || SUBSTRING(od.customer_name FROM 1 FOR 3) || '%'
WHERE 
    spd.available_quantity > 50
ORDER BY 
    spd.supply_cost DESC, od.order_date ASC;
