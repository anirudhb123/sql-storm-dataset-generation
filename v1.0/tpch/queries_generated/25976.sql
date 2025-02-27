WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' provides ', p.p_name, ' with quantity of ', ps.ps_availqty, ' at a cost of ', ps.ps_supplycost) AS supplier_part_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        o.o_orderdate AS order_date,
        o.o_totalprice AS total_price,
        CONCAT(c.c_name, ' placed order ', o.o_orderkey, ' totaling ', o.o_totalprice, ' on ', o.o_orderdate) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
LineItemSummary AS (
    SELECT 
        l.l_orderkey AS order_key,
        COUNT(l.l_linenumber) AS line_item_count,
        SUM(l.l_extendedprice) AS total_extended_price,
        AVG(l.l_discount) AS avg_discount
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    spd.supplier_part_info,
    cod.customer_order_info,
    lis.line_item_count,
    lis.total_extended_price,
    lis.avg_discount
FROM 
    SupplierPartDetails spd
JOIN 
    CustomerOrderDetails cod ON spd.available_quantity > 0
JOIN 
    LineItemSummary lis ON lis.order_key = cod.order_key
WHERE 
    spd.supply_cost < 100 AND lis.line_item_count > 2
ORDER BY 
    lis.total_extended_price DESC, cod.order_date ASC;
